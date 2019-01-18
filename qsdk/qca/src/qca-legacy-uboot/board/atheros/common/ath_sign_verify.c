/*
 * Copyright (c) 2015 The Linux Foundation. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 and
 * only version 2 as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 */

#include <common.h>
#include <image.h>
#include <asm/byteorder.h>
#include <config.h>

#include "polarssl-mini/sha256.h"
#include "polarssl-mini/rsa.h"

#include "ath_flash.h"

struct squashfs_super_block {
	u32 s_magic;
	u32 pad0[9];
	u32 bytes_used;
	u32 pad1;
};

struct ubi_ec_hdr {
	u32 magic;
	u32 pad0[4];
	u32 data_offset;
	u32 image_seq;
	u32 pad1[9];
};

static int rsa_otp_key_cmp(void)
{
#ifdef CONFIG_SECURITY_OTP
	int i;
	char *otp_key = (char *)0x81800000;
	const char *pubkey = (const char *)CONFIG_RSA_N;

	if (!ath_otp_is_locked()) {
		ath_otp_write(pubkey, strlen(CONFIG_RSA_N));

		printf("OTP is not locked, save pubkey to OTP\n");

		ath_otp_lock_all();
	}

	ath_otp_read(otp_key, strlen(CONFIG_RSA_N));

	for (i = 0; i < strlen(CONFIG_RSA_N); i++) {
		if (otp_key[i] != pubkey[i]) {
			printf("FATAL ERROR: invalid public key!\n");
			return -1;
		}
	}
#endif

	return 0;
}

static int rsa_pub_key_get(rsa_context *rsa)
{
	rsa_init(rsa, RSA_PKCS_V15, 0);

	if (!CONFIG_RSA_N || !CONFIG_RSA_E || strlen(CONFIG_RSA_N) < 256 ||
	    !strlen(CONFIG_RSA_E))
		return -1;

	if (rsa_otp_key_cmp())
		return -1;

	mpi_read_string(&rsa->N, 16, CONFIG_RSA_N);
	mpi_read_string(&rsa->E, 16, CONFIG_RSA_E);

	rsa->len = (mpi_msb(&rsa->N) + 7) >> 3;

	return 0;
}

static int rsa_sign_verify(rsa_context *rsa, u8 *hash, u8 *sign)
{
	int ret = rsa_pkcs1_verify(rsa, NULL, NULL, RSA_PUBLIC,
				   POLARSSL_MD_SHA256, 32, hash, sign);

	return ret;
}

static int rootfs_sign_verify_squashfs(u32 k_addr, u32 k_offset, u8 *r_sign)
{
	u32 r_mask, r_len, r_addr;
	u8 hash[32];
	rsa_context rsa;
	sha256_context ctx;
	struct squashfs_super_block *shdr;
	u8 eof[4] = { 0xde, 0xad, 0xc0, 0xde };

	/* RKImage only */
	r_addr = k_offset - ATH_F_LEN;
	shdr = (void *)r_addr;

	/* Only for squashfs */
	if (le32_to_cpu(shdr->s_magic) != 0x73717368) {
		printf("Unknow filesystem\n");
		return -1;
	}

	/* size align */
	r_len = le32_to_cpu(shdr->bytes_used);
	r_mask = CFG_FLASH_SECTOR_SIZE - 1;
	r_len = (r_len + r_mask) & (~r_mask);

	sha256_starts(&ctx);
	sha256_update(&ctx, (u8 *)r_addr, r_len);
	sha256_update(&ctx, eof, sizeof eof);
	sha256_finish(&ctx, hash);

	if (rsa_pub_key_get(&rsa) < 0) {
		printf("No valid pub key found\n");
		return -1;
	}

	if (rsa_sign_verify(&rsa, hash, r_sign)) {
		printf("Rootfs sign verify failed\n");
		return -1;
	}

	return 0;
}

#ifdef ATH_SPI_NAND
#include <nand.h>
static int rootfs_sign_verify_ubifs(u32 k_addr, u32 k_offset, u8 *r_sign)
{
	rsa_context rsa;
	sha256_context ctx;
	u32 r_mask, r_len, r_offset, r_blocks, i_blocks;
	u8 hash[32], *block_buf = (u8 *)(k_addr + ATH_K_LEN);
	u32 ubi_data_offset, block_data_size, block_size = 0x20000;
	int image_found = 0;
	u8 eof[4] = { 0xde, 0xad, 0xc0, 0xde };
	nand_info_t *nand = &nand_info[0];
	struct ubi_ec_hdr *uhdr;

	/* KRImage only */
	r_offset = k_offset + ATH_K_LEN;

	if (nand_read(nand, r_offset, &block_size, block_buf) < 0) {
		printf("nand read heaher failed!\n");
		return -1;
	}

	/* UBI erase counter header */
	uhdr = (struct ubi_ec_hdr *)block_buf;
	if (be32_to_cpu(uhdr->magic) != 0x55424923) {
		printf("Error, invalid magic\n");
		return -1;
	}

	ubi_data_offset = be32_to_cpu(uhdr->data_offset);
	block_data_size = block_size - ubi_data_offset;
	r_blocks = ATH_F_LEN / block_size;

	for (i_blocks = 0; i_blocks < r_blocks; i_blocks++) {
		u8 *data = block_buf + ubi_data_offset;

		/* read one block */
		if (nand_read(nand, r_offset + i_blocks * block_size, &block_size, block_buf) < 0)
			continue;

		if (!image_found) {
			struct squashfs_super_block *shdr;

			shdr = (struct squashfs_super_block *)data;

			/* Only for squashfs */
			if (le32_to_cpu(shdr->s_magic) != 0x73717368)
				continue;

			/* size align */
			r_len = le32_to_cpu(shdr->bytes_used);
			r_mask = CFG_FLASH_SECTOR_SIZE - 1;
			r_len = (r_len + r_mask) & (~r_mask);

			sha256_starts(&ctx);
			image_found = 1;
		}

		if (image_found) {
			if (r_len >= block_data_size) {
				sha256_update(&ctx, data, block_data_size);
				r_len -= block_data_size;
			} else if (r_len) {
				sha256_update(&ctx, data, r_len);
				break;
			}
		}
	}

	if (!image_found) {
		printf("No valid squashfs found\n");
		return -1;
	}

	sha256_update(&ctx, eof, sizeof eof);
	sha256_finish(&ctx, hash);

	if (rsa_pub_key_get(&rsa) < 0) {
		printf("No valid pub key found\n");
		return -1;
	}

	if (rsa_sign_verify(&rsa, hash, r_sign)) {
		printf("Rootfs sign verify failed\n");
		return -1;
	}

	return 0;
}
#else
static int rootfs_sign_verify_ubifs(u32 k_addr, u32 k_offset, u8 *r_sign)
{
	return 0;
}
#endif

static int rootfs_sign_verify(u32 k_addr, u8 *r_sign)
{
	char *str, *bootcmd = getenv("bootcmd");
	u32 k_offset;

	if (!bootcmd || !strlen(bootcmd)) {
		printf("No bootcmd found\n");
		return -1;
	}

	if (strstr(bootcmd, "bootm")) {
		str = bootcmd + strlen("bootm ");
		k_offset = simple_strtoul(str, NULL, 16);

		return rootfs_sign_verify_squashfs(k_addr, k_offset, r_sign);
	} else {
		str = bootcmd + strlen("nboot 0x81000000 0 ");
		k_offset = simple_strtoul(str, NULL, 16);

		return rootfs_sign_verify_ubifs(k_addr, k_offset, r_sign);
	}
}

static int kernel_sign_verify(u32 k_addr, u32 k_len, u8 *k_sign)
{
	u8 hash[32];
	rsa_context rsa;
	sha256_context ctx;

	if (rsa_pub_key_get(&rsa) < 0) {
		printf("No valid pub key found\n");
		return -1;
	}

	sha256_starts(&ctx);
	sha256_update(&ctx, ((u8 *)k_addr), k_len);
	sha256_finish(&ctx, hash);

	if (rsa_sign_verify(&rsa, hash, k_sign)) {
		printf("Kernel sign verify failed\n");
		return -1;
	}

	return 0;
}

int ath_sign_verify(u32 k_addr, image_header_t *hdr)
{
	u32 k_len = ntohl(hdr->ih_size) + sizeof(*hdr);
	u8 *k_sign = (u8 *)(k_addr + k_len);
	u8 *r_sign = k_sign + 256;

	if (kernel_sign_verify(k_addr, k_len, k_sign) < 0)
		return -1;

	if (rootfs_sign_verify(k_addr, r_sign) < 0)
		return -1;

	return 0;
}

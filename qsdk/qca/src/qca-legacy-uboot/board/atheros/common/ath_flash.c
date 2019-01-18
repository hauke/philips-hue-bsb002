/*
 * Copyright (c) 2013 The Linux Foundation. All rights reserved.
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
#include <jffs2/jffs2.h>
#include <asm/addrspace.h>
#include <asm/types.h>
#include <atheros.h>
#include "ath_flash.h"

#if !defined(ATH_DUAL_FLASH)
#	define	ath_spi_flash_print_info	flash_print_info
#endif

#define ATH_16M_FLASH_SIZE		0x1000000
#define ATH_GET_EXT_3BS(addr)		((addr) % ATH_16M_FLASH_SIZE)
#define ATH_GET_EXT_4B(addr)		((addr) >> 24)

static u32 ath_device_id;

/*
 * globals
 */
flash_info_t flash_info[CFG_MAX_FLASH_BANKS];

/*
 * statics
 */
static void ath_spi_write_enable(void);
static void ath_spi_poll(void);
#if !defined(ATH_SST_FLASH)
static void ath_spi_write_page(uint32_t addr, uint8_t * data, int len);
#endif
static void ath_spi_sector_erase(uint32_t addr);

#if defined(ATH_DUAL_NOR)
static void ath_spi_enter_ext_addr(u8 addr)
{
	ath_spi_write_enable();
	ath_reg_wr_nf(ATH_SPI_WRITE, ATH_SPI_CS_DIS);
	ath_spi_bit_banger(ATH_SPI_CMD_WR_EXT);
	ath_spi_bit_banger(addr);
	ath_spi_go();
	ath_spi_poll();
}

static void ath_spi_exit_ext_addr(int ext)
{
	if (ext)
		ath_spi_enter_ext_addr(0);
}
#else
#define ath_spi_enter_ext_addr(addr)
#define ath_spi_exit_ext_addr(ext)
#endif

static void
ath_spi_read_id(void)
{
	ath_reg_wr_nf(ATH_SPI_WRITE, ATH_SPI_CS_DIS);
	ath_spi_bit_banger(ATH_SPI_CMD_RDID);
	ath_spi_delay_8();
	ath_spi_delay_8();
	ath_spi_delay_8();
	ath_spi_go();

	ath_device_id = ath_reg_rd(ATH_SPI_RD_STATUS) & 0xffffff;

	printf("Flash Manuf Id 0x%x, DeviceId0 0x%x, DeviceId1 0x%x\n",
			(ath_device_id >> 16) & 0xff,
			(ath_device_id >> 8) & 0xff,
			(ath_device_id >> 0) & 0xff);
}


#ifdef ATH_SST_FLASH
void ath_spi_flash_unblock(void)
{
	ath_spi_write_enable();
	ath_spi_bit_banger(ATH_SPI_CMD_WRITE_SR);
	ath_spi_bit_banger(0x0);
	ath_spi_go();
	ath_spi_poll();
}
#endif

#if  defined(CONFIG_ATH_SPI_CS1_GPIO)

#define ATH_SPI_CS0_GPIO		5

static void ath_gpio_config_output(int gpio)
{
#if defined(CONFIG_MACH_AR934x) || \
	defined(CONFIG_MACH_QCA955x) || \
	defined(CONFIG_MACH_QCA953x) || \
	defined(CONFIG_MACH_QCA956x)
	ath_reg_rmw_clear(ATH_GPIO_OE, (1 << gpio));
#else
	ath_reg_rmw_set(ATH_GPIO_OE, (1 << gpio));
#endif
}

static void ath_gpio_set_fn(int gpio, int fn)
{
#define gpio_fn_reg(x)  ((x) / 4)
#define gpio_lsb(x)     (((x) % 4) * 8)
#define gpio_msb(x)     (gpio_lsb(x) + 7)
#define gpio_mask(x)    (0xffu << gpio_lsb(x))
#define gpio_set(x, f)  (((f) & 0xffu) << gpio_lsb(x))

	uint32_t *reg = ((uint32_t *)GPIO_OUT_FUNCTION0_ADDRESS) +
				gpio_fn_reg(gpio);

	ath_reg_wr(reg, (ath_reg_rd(reg) & ~gpio_mask(gpio)) | gpio_set(gpio, fn));
}

int ath_spi_flash_get_fn_cs0(void)
{
#if CONFIG_MACH_QCA934x
	return 0x09;
#elif (CONFIG_MACH_QCA953x || CONFIG_MACH_QCA955x)
	return 0x09;
#endif
	return -1;
}

int ath_spi_flash_get_fn_cs1(void)
{
#if CONFIG_MACH_QCA934x
	return 0x07;
#elif (CONFIG_MACH_QCA953x || CONFIG_MACH_QCA955x)
	return 0x0a;
#endif
	return -1;
}

void ath_spi_flash_enable_cs1(void)
{
	int fn = ath_spi_flash_get_fn_cs1();

	if (fn < 0) {
		printf("Error, enable SPI_CS_1 failed\n");
		return;
	}

	ath_gpio_set_fn(CONFIG_ATH_SPI_CS1_GPIO,
			ath_spi_flash_get_fn_cs1());
	ath_gpio_config_output(CONFIG_ATH_SPI_CS1_GPIO);
}
#else
#define ath_spi_flash_enable_cs1(...)
#endif

int flash_select(int chip)
{
#if  defined(CONFIG_ATH_SPI_CS1_GPIO)
	int fn_cs0, fn_cs1;

	fn_cs0 = ath_spi_flash_get_fn_cs0();
	fn_cs1 = ath_spi_flash_get_fn_cs1();

	if (fn_cs0 < 0 || fn_cs1 < 0) {
		printf("Error, flash select failed\n");
		return -1;
	}
#endif

	switch (chip) {
	case 0:
#if  defined(CONFIG_ATH_SPI_CS1_GPIO)
		ath_gpio_set_fn(CONFIG_ATH_SPI_CS1_GPIO, fn_cs1);
		ath_gpio_set_fn(ATH_SPI_CS0_GPIO, fn_cs0);
#elif defined(ATH_DUAL_NOR)
		ath_reg_rmw_set(ATH_SPI_FS, 1);
		ath_spi_exit_ext_addr(1);
		ath_reg_rmw_clear(ATH_SPI_FS, 1);
#endif
		break;

	case 1:
#if  defined(CONFIG_ATH_SPI_CS1_GPIO)
		ath_gpio_set_fn(ATH_SPI_CS0_GPIO, 0);
		ath_gpio_set_fn(CONFIG_ATH_SPI_CS1_GPIO, fn_cs0);
#elif defined(ATH_DUAL_NOR)
		ath_reg_rmw_set(ATH_SPI_FS, 1);
		ath_spi_enter_ext_addr(1);
		ath_reg_rmw_clear(ATH_SPI_FS, 1);
#endif
		break;

	default:
		printf("Error, please specify correct flash number 0/1\n");
		return -1;
	}

	return 0;
}

unsigned long flash_init(void)
{
#if !(defined(CONFIG_WASP_SUPPORT) || defined(CONFIG_MACH_QCA955x) || defined(CONFIG_MACH_QCA956x))
#ifdef ATH_SST_FLASH
	ath_reg_wr_nf(ATH_SPI_CLOCK, 0x3);
	ath_spi_flash_unblock();
	ath_reg_wr(ATH_SPI_FS, 0);
#else
	ath_reg_wr_nf(ATH_SPI_CLOCK, 0x43);
#endif
#endif

#if  defined(CONFIG_MACH_QCA953x) /* Added for HB-SMIC */
#ifdef ATH_SST_FLASH
	ath_reg_wr_nf(ATH_SPI_CLOCK, 0x4);
	ath_spi_flash_unblock();
	ath_reg_wr(ATH_SPI_FS, 0);
#else
	ath_reg_wr_nf(ATH_SPI_CLOCK, 0x44);
#endif
#endif 
	ath_reg_rmw_set(ATH_SPI_FS, 1);
	ath_spi_read_id();
	ath_spi_exit_ext_addr(1);
	ath_reg_rmw_clear(ATH_SPI_FS, 1);

	ath_spi_flash_enable_cs1();

	ath_otp_detect();

	/*
	 * hook into board specific code to fill flash_info
	 */
	return (flash_get_geom(&flash_info[0]));
}

void
ath_spi_flash_print_info(flash_info_t *info)
{
	printf("The hell do you want flinfo for??\n");
}

int
flash_erase(flash_info_t *info, int s_first, int s_last)
{
	u32 addr;
	int ext = 0;
	int i, sector_size = info->size / info->sector_count;

	printf("\nFirst %#x last %#x sector size %#x\n",
		s_first, s_last, sector_size);

	addr = s_first * sector_size;
	if (addr >= ATH_16M_FLASH_SIZE) {
		ext = 1;
		ath_spi_enter_ext_addr(ATH_GET_EXT_4B(addr));
	} else if (s_last * sector_size >= ATH_16M_FLASH_SIZE) {
		printf("Erase failed, cross 16M is forbidden\n");
		return -1;
	}

	for (i = s_first; i <= s_last; i++) {
		addr = i * sector_size;

		if (ext)
			addr = ATH_GET_EXT_3BS(addr);

		printf("\b\b\b\b%4d", i);
		ath_spi_sector_erase(addr);
	}

	ath_spi_exit_ext_addr(ext);

	ath_spi_done();
	printf("\n");

	return 0;
}

/*
 * Write a buffer from memory to flash:
 * 0. Assumption: Caller has already erased the appropriate sectors.
 * 1. call page programming for every 256 bytes
 */
#ifdef ATH_SST_FLASH
void
ath_spi_flash_chip_erase(void)
{
	ath_spi_write_enable();
	ath_spi_bit_banger(ATH_SPI_CMD_CHIP_ERASE);
	ath_spi_go();
	ath_spi_poll();
}

int
write_buff(flash_info_t *info, uchar *src, ulong dst, ulong len)
{
	uint32_t val;

	dst = dst - CFG_FLASH_BASE;
	printf("write len: %lu dst: 0x%x src: %p\n", len, dst, src);

	for (; len; len--, dst++, src++) {
		ath_spi_write_enable();	// dont move this above 'for'
		ath_spi_bit_banger(ATH_SPI_CMD_PAGE_PROG);
		ath_spi_send_addr(dst);

		val = *src & 0xff;
		ath_spi_bit_banger(val);

		ath_spi_go();
		ath_spi_poll();
	}
	/*
	 * Disable the Function Select
	 * Without this we can't read from the chip again
	 */
	ath_reg_wr(ATH_SPI_FS, 0);

	if (len) {
		// how to differentiate errors ??
		return ERR_PROG_ERROR;
	} else {
		return ERR_OK;
	}
}
#else
int
write_buff(flash_info_t *info, uchar *source, ulong addr, ulong len)
{
	int total = 0, len_this_lp, bytes_this_page;
	ulong dst;
	uchar *src;
	int ext = 0;

	printf("write addr: %x\n", addr);
	addr = addr - CFG_FLASH_BASE;

	if (addr >= ATH_16M_FLASH_SIZE) {
		ext = 1;
		ath_spi_enter_ext_addr(ATH_GET_EXT_4B(addr));
		addr = ATH_GET_EXT_3BS(addr);
	} else if (addr + len >= ATH_16M_FLASH_SIZE) {
		printf("Write failed, cross 16M is forbidden\n");
		return -1;
	}

	while (total < len) {
		src = source + total;
		dst = addr + total;
		bytes_this_page =
			ATH_SPI_PAGE_SIZE - (addr % ATH_SPI_PAGE_SIZE);
		len_this_lp =
			((len - total) >
			bytes_this_page) ? bytes_this_page : (len - total);
		ath_spi_write_page(dst, src, len_this_lp);
		total += len_this_lp;
	}

	ath_spi_exit_ext_addr(ext);

	ath_spi_done();

	return 0;
}
#endif

static void
ath_spi_write_enable()
{
	ath_reg_wr_nf(ATH_SPI_FS, 1);
	ath_reg_wr_nf(ATH_SPI_WRITE, ATH_SPI_CS_DIS);
	ath_spi_bit_banger(ATH_SPI_CMD_WREN);
	ath_spi_go();
}

static void
ath_spi_poll()
{
	int rd;

	do {
		ath_reg_wr_nf(ATH_SPI_WRITE, ATH_SPI_CS_DIS);
		ath_spi_bit_banger(ATH_SPI_CMD_RD_STATUS);
		ath_spi_delay_8();
		rd = (ath_reg_rd(ATH_SPI_RD_STATUS) & 1);
	} while (rd);
}

#if !defined(ATH_SST_FLASH)
static void
ath_spi_write_page(uint32_t addr, uint8_t *data, int len)
{
	int i;
	uint8_t ch;

	display(0x77);
	ath_spi_write_enable();
	ath_spi_bit_banger(ATH_SPI_CMD_PAGE_PROG);
	ath_spi_send_addr(addr);

	for (i = 0; i < len; i++) {
		ch = *(data + i);
		ath_spi_bit_banger(ch);
	}

	ath_spi_go();
	display(0x66);
	ath_spi_poll();
	display(0x6d);
}
#endif

static void
ath_spi_sector_erase(uint32_t addr)
{
	ath_spi_write_enable();
	ath_spi_bit_banger(ATH_SPI_CMD_SECTOR_ERASE);
	ath_spi_send_addr(addr);
	ath_spi_go();
	display(0x7d);
	ath_spi_poll();
}

#ifdef ATH_DUAL_FLASH
void flash_print_info(flash_info_t *info)
{
	ath_spi_flash_print_info(NULL);
	ath_nand_flash_print_info(NULL);
}
#endif

#ifdef CONFIG_SECURITY_OTP
#define ATH_SPI_CMD_RD_OTP_STATUS	0x35
#define ATH_SPI_CMD_WR_OTP_STATUS1	0x01
#define ATH_SPI_CMD_WR_OTP_STATUS2	0x31
#define ATH_SPI_CMD_WR_OTP		0x42
#define ATH_SPI_CMD_ERASE_OTP		0x44
#define ATH_SPI_CMD_RD_OTP		0x48

#define OTP_LOCK_MASK			0x38
#define ALIGN(x, a)			(((x) + (a) - 1) & ~((a) - 1))
#define ARRAY_SIZE(x)			(sizeof(x) / sizeof((x)[0]))

struct ath_otp_priv {
	u32 device_id;
	u16 page_size;
	u16 page_num;
	u32 otp_size;
	u32 write_size;
	int only_status1;
};

static struct ath_otp_priv ath_otp_ids[] = {
	{ /* GD25Q41B */
		0xc84013,
		512,
		3,
		512 * 3,
		256,
		0,
	},
	{ /* W25Q40CL */
		0xef4013,
		256,
		3,
		256 * 3,
		256,
		1,
	},
	{ /* GD25Q128C */
		0xc84018,
		256,
		3,
		256 * 3,
		256,
		0,
	},
	{ /* W25Q128FV */
		0xef4018,
		256,
		3,
		256 * 3,
		256,
		0,
	},
	{ /* GD25Q256C */
		0xc84019,
		256,
		3,
		256 * 3,
		256,
		0,
	},
	{ /* W25Q256FV */
		0xef4019,
		256,
		3,
		256 * 3,
		256,
		0,
	},
	/* add new otp here */
};

static struct ath_otp_priv *ath_otp_info = NULL;

void ath_otp_detect(void)
{
	int id;

	for (id = 0; id < ARRAY_SIZE(ath_otp_ids); id++) {
		if (ath_device_id == ath_otp_ids[id].device_id) {
			ath_otp_info = &ath_otp_ids[id];
			break;
		}
	}
}

static int ath_otp_supported(void)
{
	return ath_otp_info ? 1 : 0;
}

int ath_otp_is_locked(void)
{
	if (!ath_otp_supported())
		return 0;

	ath_reg_wr_nf(ATH_SPI_FS, 1);
	ath_reg_wr_nf(ATH_SPI_WRITE, ATH_SPI_CS_DIS);
	ath_spi_bit_banger(ATH_SPI_CMD_RD_OTP_STATUS);
	ath_spi_delay_8();
	ath_spi_go();

	return (ath_reg_rd(ATH_SPI_RD_STATUS) & OTP_LOCK_MASK);
}

static void __ath_otp_lock(u32 page)
{
	u8 s1, s2;

	ath_reg_wr_nf(ATH_SPI_FS, 1);

	if (ath_otp_info->only_status1) {
		/* read status bits: S7-S0 */
		ath_reg_wr_nf(ATH_SPI_WRITE, ATH_SPI_CS_DIS);
		ath_spi_bit_banger(ATH_SPI_CMD_RD_STATUS);
		ath_spi_delay_8();
		ath_spi_go();

		s1 = ath_reg_rd(ATH_SPI_RD_STATUS) & 0xFF;
	}

	/* read status bits: S15-S8 */
	ath_reg_wr_nf(ATH_SPI_WRITE, ATH_SPI_CS_DIS);
	ath_spi_bit_banger(ATH_SPI_CMD_RD_OTP_STATUS);
	ath_spi_delay_8();
	ath_spi_go();

	s2 = ath_reg_rd(ATH_SPI_RD_STATUS) & 0xFF;

	ath_spi_done();

	/* S11, S12, S13 */
	s2 |= 1 << (2 + page);

	ath_spi_write_enable();
	ath_reg_wr_nf(ATH_SPI_WRITE, ATH_SPI_CS_DIS);

	if (ath_otp_info->only_status1) {
		ath_spi_bit_banger(ATH_SPI_CMD_WR_OTP_STATUS1);
		ath_spi_bit_banger(s1);
		ath_spi_bit_banger(s2);
	} else {
		ath_spi_bit_banger(ATH_SPI_CMD_WR_OTP_STATUS2);
		ath_spi_bit_banger(s2);
	}

	ath_spi_go();
	ath_spi_poll();
	ath_spi_done();
}

void ath_otp_lock_all(void)
{
	int page;

	if (!ath_otp_supported())
		return;

	for (page = 0; page < ath_otp_info->page_num; page++)
		__ath_otp_lock(page + 1);
}

void ath_otp_lock_page(u32 page)
{
	if (!page || !ath_otp_supported() ||
	    page > ath_otp_info->page_num)
		return;

	__ath_otp_lock(page);
}

static void __ath_otp_erase(u32 id)
{
	u32 addr = id << 12;

	ath_spi_write_enable();
	ath_spi_bit_banger(ATH_SPI_CMD_ERASE_OTP);
	ath_spi_send_addr(addr);
	ath_spi_go();
	ath_spi_poll();

	ath_spi_done();
}

static void ath_otp_erase(void)
{
	int i;

	for (i = 0; i < ath_otp_info->page_num; i++)
		__ath_otp_erase(i + 1);
}

static u32 ath_otp_read_words(u32 addr)
{
	ath_reg_rmw_set(ATH_SPI_FS, 1);
	ath_reg_wr_nf(ATH_SPI_WRITE, ATH_SPI_CS_DIS);
	ath_spi_bit_banger(ATH_SPI_CMD_RD_OTP);
	ath_spi_send_addr(addr);
	ath_spi_bit_banger(0x00); /* dummy */

	ath_spi_delay_8();
	ath_spi_delay_8();
	ath_spi_delay_8();
	ath_spi_delay_8();

	ath_spi_go();

	u32 ret = ath_reg_rd(ATH_SPI_RD_STATUS);

	ath_spi_done();

	return ret;
}

static int ath_otp_read_page(u32 page, u8 *buf, u32 buflen)
{
	u32 addr, i, words;
	u32 *data = (u32 *)buf;

	if (!page || !buf || !buflen ||
	    page > ath_otp_info->page_num)
		return - 1;

	buflen = ALIGN(buflen, sizeof(u32));
	words = buflen >> 2;

	for (i = 0; i < words; i++) {
		addr = (page << 12) | (i << 2);
		*(data + i) = ath_otp_read_words(addr);
	}

	return 0;
}

/* read whole otp area, buflen > otp_page_size * 3 */
int ath_otp_read(u8 *buf, u32 buflen)
{
	u32 i, pages, align_offset;
	u32 page_size, otp_size;

	if (!buf || !buflen || !ath_otp_supported())
		return -1;

	page_size = ath_otp_info->page_size;
	otp_size = ath_otp_info->otp_size;

	if (buflen > otp_size)
		return -1;

	align_offset = buflen % page_size;
	pages = buflen / page_size;

	if (align_offset)
		pages += 1;

	for (i = 0; i < pages; i++) {
		u32 r_bytes;
		u8 *dbuf = buf + page_size * i;

		if (align_offset && (i == pages - 1))
			r_bytes = align_offset;
		else
			r_bytes = page_size;

		ath_otp_read_page(i + 1, dbuf, r_bytes);
	}

	return 0;
}

static void ath_otp_write_page(u32 page, u32 saddr, u8 *data, u32 datalen)
{
	u32 j;

	if (!page || page > ath_otp_info->page_num)
		return;

	ath_spi_write_enable();
	ath_spi_bit_banger(ATH_SPI_CMD_WR_OTP);
	ath_spi_send_addr((page << 12) | saddr);

	for (j = 0; j < datalen; j++)
		ath_spi_bit_banger(*(data + j));

	ath_spi_go();
	ath_spi_poll();
	ath_spi_done();
}

/* write the data to whole otp area, the data length is page_size * 3 */
int ath_otp_write(u8 *data, u32 datalen)
{
	u32 i, pages, align_offset;
	u32 page_size, otp_size, write_size;

	if (!data || !datalen || !ath_otp_supported())
		return -1;

	page_size = ath_otp_info->page_size;
	otp_size = ath_otp_info->otp_size;
	write_size = ath_otp_info->write_size;

	if (datalen > otp_size)
		return -1;

	align_offset = datalen % page_size;
	pages = datalen / page_size;

	if (align_offset)
		pages += 1;

	/* return if one of the otp page is locked*/
	if (ath_otp_is_locked())
		return -1;

	/* erase all pages */
	ath_otp_erase();

	for (i = 0; i < pages; i++) {
		u32 w_bytes;
		u8 *wd = data + page_size * i;

		if (align_offset && (i == pages - 1))
			w_bytes = align_offset;
		else
			w_bytes = page_size;

		if (w_bytes <= write_size) {
			ath_otp_write_page(i + 1, 0, wd, w_bytes);
		} else {
			ath_otp_write_page(i + 1, 0, wd, write_size);
			ath_otp_write_page(i + 1, write_size, wd + write_size,
					   w_bytes - write_size);
		}
	}

	return 0;
}

#endif

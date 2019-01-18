/*
 * Philips hue BSB002 bridge board support
 *
 * Copyright (c) 2015 Philips Lighting. All rights reserved.
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

#include <linux/platform_device.h>
#include <linux/ath9k_platform.h>
#include <linux/ar8216_platform.h>
#include <asm/mach-ath79/ar71xx_regs.h>
#include <linux/mtd/mtd.h>
#include <linux/mtd/partitions.h>
#include <linux/i2c.h>
#include <linux/i2c-gpio.h>

#include "common.h"
#include "dev-eth.h"
#include "dev-gpio-buttons.h"
#include "dev-leds-gpio.h"
#include "dev-m25p80.h"
#include "dev-spi.h"
#include "dev-usb.h"
#include "dev-wmac.h"
#include "dev-i2c.h"
#include "machtypes.h"


#define BSB002_GPIO_LED_PORTAL			2
#define BSB002_GPIO_LED_NETWORK			3

#define BSB002_GPIO_LINK_BUTTON			1
#define BSB002_GPIO_FACTORY_RESET_BUTTON	0

#define BSB002_GPIO_SAMR21_BOOTn		13
#define BSB002_GPIO_SAMR21_RSTn			15

#define BSB002_GPIO_MFI_RST			14
#define BSB002_GPIO_MFI_SCL			16
#define BSB002_GPIO_MFI_SDA			12
#define BSB002_GPIO_MFI_SDA_INPUT		17

#define BSB002_GPIO_TX_FRAME			4

#define BSB002_KEYS_POLL_INTERVAL		20
#define BSB002_KEYS_DEBOUNCE_INTERVAL		(3 * BSB002_KEYS_POLL_INTERVAL)

#define BSB002_MAC0_OFFSET			0
#define BSB002_MAC1_OFFSET			6
#define BSB002_WMAC_CALDATA_OFFSET		0x1000

static void __init disable_jtag_to_enable_gpios_0_through_3(void)
{
	ath79_gpio_function_enable(AR934X_GPIO_FUNC_JTAG_DISABLE);
}

static void __init setup_gpio_for_output(unsigned gpio)
{
	ath79_gpio_output_select(gpio, AR934X_GPIO_OUT_GPIO); /* Sets the pin function, not direction */
	ath79_gpio_direction_select(gpio, true);
}

static void __init setup_gpio_for_button(unsigned gpio)
{
	ath79_gpio_output_select(gpio, AR934X_GPIO_OUT_GPIO); /* Sets the pin function, not direction */
	ath79_gpio_direction_select(gpio, false);
}

static struct gpio_led bsb002_leds_gpio[] __initdata = {
	{
		.name		= "bsb002:blue:portal",
		.gpio		= BSB002_GPIO_LED_PORTAL,
		.active_low	= 0,
	},
	{
		.name		= "bsb002:blue:network",
		.gpio		= BSB002_GPIO_LED_NETWORK,
		.active_low	= 0,
	},
};

static void __init bsb002_gpio_led_setup(void)
{
	disable_jtag_to_enable_gpios_0_through_3();

	setup_gpio_for_output(BSB002_GPIO_LED_PORTAL);
	setup_gpio_for_output(BSB002_GPIO_LED_NETWORK);

	ath79_register_leds_gpio(-1,
				 ARRAY_SIZE(bsb002_leds_gpio),
				 bsb002_leds_gpio);
}

static struct gpio_keys_button bsb002_gpio_keys[] __initdata = {
	{
		.desc		= "Link button",
		.type		= EV_KEY,
		.code		= BTN_0,
		.debounce_interval = BSB002_KEYS_DEBOUNCE_INTERVAL,
		.gpio		= BSB002_GPIO_LINK_BUTTON,
		.active_low	= 0,
	},
	{
		.desc		= "Reset button",
		.type		= EV_KEY,
		.code		= BTN_1,
		.debounce_interval = BSB002_KEYS_DEBOUNCE_INTERVAL,
		.gpio		= BSB002_GPIO_FACTORY_RESET_BUTTON,
		.active_low	= 0,
	},
};

static void __init bsb002_gpio_button_setup(void)
{
	setup_gpio_for_button(BSB002_GPIO_FACTORY_RESET_BUTTON);
	setup_gpio_for_button(BSB002_GPIO_LINK_BUTTON);

	ath79_register_gpio_keys_polled(-1, BSB002_KEYS_POLL_INTERVAL,
					ARRAY_SIZE(bsb002_gpio_keys),
					bsb002_gpio_keys);
}

static void __init bsb002_gpio_controls_setup(void)
{
	setup_gpio_for_output(BSB002_GPIO_SAMR21_BOOTn);
	setup_gpio_for_output(BSB002_GPIO_SAMR21_RSTn);
	setup_gpio_for_output(BSB002_GPIO_TX_FRAME);
}

static struct i2c_gpio_platform_data ath79_i2c_gpio_data = {
	.sda_pin = BSB002_GPIO_MFI_SDA,
	.scl_pin = BSB002_GPIO_MFI_SCL,
};

static void __init bsb002_register_i2c_devices(
		struct i2c_board_info const *info)
{
	ath79_gpio_output_select(BSB002_GPIO_MFI_SDA, AR934X_GPIO_OUT_GPIO);
	ath79_gpio_output_select(BSB002_GPIO_MFI_SCL, AR934X_GPIO_OUT_GPIO);

	ath79_register_i2c(&ath79_i2c_gpio_data, info, info ? 1 : 0);
}

static void __init bsb002_common_setup(void)
{
	u8 *art = (u8 *) KSEG1ADDR(0x1fff0000);

	bsb002_gpio_led_setup();
	bsb002_gpio_button_setup();
	bsb002_gpio_controls_setup();

	ath79_register_usb();

	ath79_register_wmac(art + BSB002_WMAC_CALDATA_OFFSET, NULL);

	ath79_register_mdio(0, 0x0);
	ath79_register_mdio(1, 0x0);

	ath79_init_mac(ath79_eth0_data.mac_addr, art + BSB002_MAC0_OFFSET, 0);
	ath79_init_mac(ath79_eth1_data.mac_addr, art + BSB002_MAC1_OFFSET, 0);

	/* WAN port */
	ath79_eth0_data.phy_if_mode = PHY_INTERFACE_MODE_MII;
	ath79_eth0_data.speed = SPEED_100;
	ath79_eth0_data.duplex = DUPLEX_FULL;
	ath79_eth0_data.phy_mask = BIT(4);
	ath79_register_eth(0);

	/* LAN ports */
	ath79_eth1_data.phy_if_mode = PHY_INTERFACE_MODE_GMII;
	ath79_eth1_data.speed = SPEED_1000;
	ath79_eth1_data.duplex = DUPLEX_FULL;
	ath79_switch_data.phy_poll_mask |= BIT(4);
	ath79_switch_data.phy4_mii_en = 1;
	ath79_register_eth(1);

	/* GPIO based S/W I2C master device */
	bsb002_register_i2c_devices(NULL);
}

static struct ath79_spi_controller_data bsb002_spi0_cdata =
{
	.cs_type	= ATH79_SPI_CS_TYPE_INTERNAL,
	.is_flash	= true,
	.cs_line	= 0,
};

static struct ath79_spi_controller_data bsb002_spi1_cdata =
{
	.cs_type	= ATH79_SPI_CS_TYPE_INTERNAL,
	.is_flash	= true,
	.cs_line	= 1,
};

static struct spi_board_info bsb002_spi_info[] = {
	{
		.bus_num	= 0,
		.chip_select	= 0,
		.max_speed_hz	= 25000000,
		.modalias	= "m25p80",
		.controller_data = &bsb002_spi0_cdata,
		.platform_data 	= NULL,
	},
	{
		.bus_num	= 0,
		.chip_select	= 1,
		.max_speed_hz   = 26000000,
		.modalias	= "ath79-spinand",
		.controller_data = &bsb002_spi1_cdata,
		.platform_data 	= NULL,
	}
};

static struct ath79_spi_platform_data bsb002_spi_data = {
	.bus_num		= 0,
	.num_chipselect		= 2,
	.word_banger            = true,
};

static void __init bsb002_nand_setup(void)
{
	ath79_register_spi(&bsb002_spi_data, bsb002_spi_info, 2);
	bsb002_common_setup();
}

MIPS_MACHINE(ATH79_MACH_BSB002, "BSB002", "Philips BSB002 board",
	     bsb002_nand_setup);


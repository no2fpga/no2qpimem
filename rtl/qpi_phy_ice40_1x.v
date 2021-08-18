/*
 * qpi_phy_ice40_1x.v
 *
 * vim: ts=4 sw=4
 *
 * Copyright (C) 2019-2021  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none

module qpi_phy_ice40_1x #(
	parameter integer N_CS = 2,				/* CS count */
	parameter integer WITH_CLK = 1,
	parameter integer NEG_IN = 0,			/* Sample on negative edge */

	// auto
	parameter integer CL = N_CS ? (N_CS-1) : 0
)(
	// Pads
	inout  wire [ 3:0] pad_io,
	output wire        pad_clk,
	output wire [CL:0] pad_cs_n,

	// PHY interface
	output wire [ 3:0] phy_io_i,
	input  wire [ 3:0] phy_io_o,
	input  wire [ 3:0] phy_io_oe,
	input  wire        phy_clk_o,
	input  wire [CL:0] phy_cs_o,

	// Clock
	input  wire clk
);

	// IOs
	wire [3:0] phy_io_i_pe;
	wire [3:0] phy_io_i_ne;

	SB_IO #(
		.PIN_TYPE    (6'b1101_00),
		.PULLUP      (1'b1),
		.NEG_TRIGGER (1'b0),
		.IO_STANDARD ("SB_LVCMOS")
	) iob_io_I[3:0] (
		.PACKAGE_PIN   (pad_io),
		.INPUT_CLK     (clk),
		.OUTPUT_CLK    (clk),
		.OUTPUT_ENABLE (phy_io_oe),
		.D_OUT_0       (phy_io_o),
		.D_IN_0        (phy_io_i_pe),
		.D_IN_1        (phy_io_i_ne)
	);

	assign phy_io_i = NEG_IN ? phy_io_i_ne : phy_io_i_pe;

	// Clock
	generate
		if (WITH_CLK) begin
			reg clk_active;

			always @(posedge clk)
				clk_active <= phy_clk_o;

			SB_IO #(
				.PIN_TYPE    (6'b0100_11),
				.PULLUP      (1'b0),
				.NEG_TRIGGER (1'b0),
				.IO_STANDARD ("SB_LVCMOS")
			) iob_clk_I (
				.PACKAGE_PIN (pad_clk),
				.OUTPUT_CLK  (clk),
				.D_OUT_0     (1'b0),
				.D_OUT_1     (clk_active)
			);
		end
	endgenerate

	// Chip select
	generate
		if (N_CS)
			SB_IO #(
				.PIN_TYPE    (6'b0101_11),
				.PULLUP      (1'b0),
				.NEG_TRIGGER (1'b0),
				.IO_STANDARD ("SB_LVCMOS")
			) iob_cs_I[N_CS-1:0] (
				.PACKAGE_PIN (pad_cs_n),
				.OUTPUT_CLK  (clk),
				.D_OUT_0     (phy_cs_o)
			);
	endgenerate

endmodule // qpi_phy_ice40_1x

/*
 * qpi_phy_ice40_2x.v
 *
 * vim: ts=4 sw=4
 *
 * Copyright (C) 2019-2021  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none

module qpi_phy_ice40_2x #(
	parameter integer N_CS = 2,				/* CS count */
	parameter integer WITH_CLK = 1,

	// auto
	parameter integer CL = N_CS ? (N_CS-1) : 0
)(
	// Pads
	inout  wire [ 3:0] pad_io,
	output wire        pad_clk,
	output wire [CL:0] pad_cs_n,

	// PHY interface
	output reg  [ 7:0] phy_io_i,
	input  wire [ 7:0] phy_io_o,
	input  wire [ 3:0] phy_io_oe,
	input  wire [ 1:0] phy_clk_o,
	input  wire [CL:0] phy_cs_o,

	// Clock
	input  wire clk_1x,
	input  wire clk_2x
);

	// IOs
	wire [3:0] phy_io_o_pe;
	reg  [3:0] phy_io_o_ne;

	wire [3:0] phy_io_i_pe;
	wire [3:0] phy_io_i_ne;
	reg  [3:0] phy_io_i_ne_r;

		// Output edge dispatch
	assign phy_io_o_pe = { phy_io_o[7], phy_io_o[5], phy_io_o[3], phy_io_o[1] };

	always @(posedge clk_1x)
		phy_io_o_ne <= { phy_io_o[6], phy_io_o[4], phy_io_o[2], phy_io_o[0] };

		// IOB
	SB_IO #(
		.PIN_TYPE    (6'b1100_00),
		.PULLUP      (1'b1),
		.NEG_TRIGGER (1'b0),
		.IO_STANDARD ("SB_LVCMOS")
	) iob_io_I[3:0] (
		.PACKAGE_PIN   (pad_io),
		.INPUT_CLK     (clk_1x),
		.OUTPUT_CLK    (clk_1x),
		.OUTPUT_ENABLE (phy_io_oe),
		.D_OUT_0       (phy_io_o_pe),
		.D_OUT_1       (phy_io_o_ne),
		.D_IN_0        (phy_io_i_pe),
		.D_IN_1        (phy_io_i_ne)
	);

		// Input edge resync
	always @(posedge clk_1x)
		phy_io_i_ne_r <= phy_io_i_ne;

	always @(posedge clk_1x)
		phy_io_i <= {
			phy_io_i_ne_r[3], phy_io_i_pe[3],
			phy_io_i_ne_r[2], phy_io_i_pe[2],
			phy_io_i_ne_r[1], phy_io_i_pe[1],
			phy_io_i_ne_r[0], phy_io_i_pe[0]
		};

	// Clock
	generate
		if (WITH_CLK) begin
			reg [1:0] clk_active;
			reg       clk_toggle;
			reg       clk_toggle_r;
			wire      clk_out;

			// Data is sent by 8 bits always, so we only use
			// one of the two signals ...
			always @(posedge clk_1x)
			begin
				clk_active <= phy_clk_o;
				clk_toggle <= ~clk_toggle;
			end

			always @(posedge clk_2x)
				clk_toggle_r <= clk_toggle;

			assign clk_out = (clk_toggle == clk_toggle_r) ? clk_active[0] : clk_active[1];

			SB_IO #(
				.PIN_TYPE    (6'b0100_11),
				.PULLUP      (1'b1),
				.NEG_TRIGGER (1'b0),
				.IO_STANDARD ("SB_LVCMOS")
			) iob_clk_I (
				.PACKAGE_PIN (pad_clk),
				.OUTPUT_CLK  (clk_2x),
				.D_OUT_0     (clk_out),
				.D_OUT_1     (1'b0)
			);
		end
	endgenerate

	// Chip select
	generate
		// FIXME register CS config ?
		// Because of potential conflict with IO site, we don't register
		// the CS signal at all and rely on the fact it's held low a bit longer
		// than needed by the controller.
		if (N_CS)
			SB_IO #(
				.PIN_TYPE    (6'b0110_11),
				.PULLUP      (1'b1),
				.NEG_TRIGGER (1'b0),
				.IO_STANDARD ("SB_LVCMOS")
			) iob_cs_I[N_CS-1:0] (
				.PACKAGE_PIN (pad_cs_n),
				.D_OUT_0     (phy_cs_o)
			);
	endgenerate

endmodule // qpi_phy_ice40_2x

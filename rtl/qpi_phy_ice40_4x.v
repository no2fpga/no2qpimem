/*
 * qpi_phy_ice40_4x.v
 *
 * vim: ts=4 sw=4
 *
 * Copyright (C) 2019-2021  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none

module qpi_phy_ice40_4x #(
	parameter integer N_CS = 2,				/* CS count */
	parameter integer WITH_CLK = 1,
	parameter integer NEG_IN = 1,			/* Sample on negative edge */

	// auto
	parameter integer CL = N_CS ? (N_CS-1) : 0
)(
	// Pads
	inout  wire [ 3:0] pad_io,
	output wire        pad_clk,
	output wire [CL:0] pad_cs_n,

	// PHY interface
	output wire [15:0] phy_io_i,
	input  wire [15:0] phy_io_o,
	input  wire [ 3:0] phy_io_oe,
	input  wire [ 3:0] phy_clk_o,
	input  wire [CL:0] phy_cs_o,

	// Clock
	input  wire clk_1x,
	input  wire clk_4x,
	input  wire clk_sync
);

	genvar i;

	wire [ 1:0] iob_clk;
	wire [ 3:0] iob_io_oe;
	wire [ 3:0] iob_io_o;
	wire [ 3:0] iob_io_i;
	reg  [CL:0] iob_cs_o;

	wire [ 3:0] iob_io_i_ne;
	wire [ 3:0] iob_io_i_pe;


	// IOs
	// ---

	// SERDES
	generate

		for (i=0; i<4; i=i+1)
		begin : bit
			wire [1:0] osd_o;
			wire [1:0] osd_oe;

			ice40_oserdes #(
				.MODE       ("DATA"),
				.SERDES_GRP ((i<<4)|2)
			) osd_oe_I (
				.d      ({4{phy_io_oe[i]}}),
				.q      (osd_oe),
				.sync   (clk_sync),
				.clk_1x (clk_1x),
				.clk_4x (clk_4x)
			);

			ice40_oserdes #(
				.MODE       ("DATA"),
				.SERDES_GRP ((i<<4))
			) osd_o_I (
				.d      (phy_io_o[4*i+:4]),
				.q      (osd_o),
				.sync   (clk_sync),
				.clk_1x (clk_1x),
				.clk_4x (clk_4x)
			);

			assign iob_io_oe[i] = osd_oe[0];
			assign iob_io_o[i]  = osd_o[0];

			ice40_iserdes #(
				.EDGE_SEL   ("SINGLE_POS"),
				.PHASE_SEL  ("STATIC"),
				.PHASE      (1),
				.SERDES_GRP ((i<<4))
			) isd_I (
				.d         ({1'b0, iob_io_i[i]}),
				.q         (phy_io_i[4*i+:4]),
				.edge_sel  (1'b0),
				.phase_sel (2'b00),
				.sync      (clk_sync),
				.clk_1x    (clk_1x),
				.clk_4x    (clk_4x)
			);
		end

	endgenerate


	// IOB
	SB_IO #(
		.PIN_TYPE      (6'b1101_00),	// Out:SDRwOE, In:DDR
		.PULLUP        (1'b0),
		.NEG_TRIGGER   (1'b0),
		.IO_STANDARD   ("SB_LVCMOS")
	) iob_spi_io_I[3:0] (
		.PACKAGE_PIN   (pad_io),
		.OUTPUT_ENABLE (iob_io_oe),
		.D_OUT_0       (iob_io_o),
		.D_IN_0        (iob_io_i_pe),
		.D_IN_1        (iob_io_i_ne),
		.OUTPUT_CLK    (clk_4x),
		.INPUT_CLK     (clk_4x)
	);

	assign iob_io_i = NEG_IN ? iob_io_i_ne : iob_io_i_pe;


	// Clock
	// -----

	generate
		if (WITH_CLK) begin
			// SERDES
			ice40_oserdes #(
				.MODE       ("CLK90_4X"),
				.SERDES_GRP ((4 << 4))
			) osd_clk_I (
				.d      (phy_clk_o),
				.q      (iob_clk),
				.sync   (clk_sync),
				.clk_1x (clk_1x),
				.clk_4x (clk_4x)
			);

			// IOB
			SB_IO #(
				.PIN_TYPE    (6'b0100_11),	// Out:DDR, In:n/a
				.PULLUP      (1'b0),
				.NEG_TRIGGER (1'b0),
				.IO_STANDARD ("SB_LVCMOS")
			) iob_clk_I (
				.PACKAGE_PIN (pad_clk),
				.D_OUT_0     (iob_clk[0]),
				.D_OUT_1     (iob_clk[1]),
				.OUTPUT_CLK  (clk_4x)
			);
		end
	endgenerate


	// Chip select
	// -----------

	generate
		if (N_CS) begin
			// Delay to match serdes delay
			always @(posedge clk_1x)
				iob_cs_o <= phy_cs_o;

			// Because of potential conflict with IO site, we don't register
			// the CS signal at all and rely on the fact it's held low a bit longer
			// than needed by the controller.
			SB_IO #(
				.PIN_TYPE    (6'b0110_11),
				.PULLUP      (1'b1),
				.NEG_TRIGGER (1'b0),
				.IO_STANDARD ("SB_LVCMOS")
			) iob_spi_cs_I[N_CS-1:0] (
				.PACKAGE_PIN (pad_cs_n),
				.D_OUT_0     (iob_cs_o)
			);
		end
	endgenerate

endmodule // qpi_phy_ice40_4x

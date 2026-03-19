//Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2018.2 (win64) Build 2258646 Thu Jun 14 20:03:12 MDT 2018
//Date        : Mon Mar 16 09:44:30 2026
//Host        : DESKTOP-QOVO705 running 64-bit major release  (build 9200)
//Command     : generate_target clock_wrapper.bd
//Design      : clock_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module clock_wrapper
   (CLK_IN1_D_0_clk_n,
    CLK_IN1_D_0_clk_p,
    clk_out1_0,
    locked_0,
    resetn_0);
  input CLK_IN1_D_0_clk_n;
  input CLK_IN1_D_0_clk_p;
  output clk_out1_0;
  output locked_0;
  input resetn_0;

  wire CLK_IN1_D_0_clk_n;
  wire CLK_IN1_D_0_clk_p;
  wire clk_out1_0;
  wire locked_0;
  wire resetn_0;

  clock clock_i
       (.CLK_IN1_D_0_clk_n(CLK_IN1_D_0_clk_n),
        .CLK_IN1_D_0_clk_p(CLK_IN1_D_0_clk_p),
        .clk_out1_0(clk_out1_0),
        .locked_0(locked_0),
        .resetn_0(resetn_0));
endmodule

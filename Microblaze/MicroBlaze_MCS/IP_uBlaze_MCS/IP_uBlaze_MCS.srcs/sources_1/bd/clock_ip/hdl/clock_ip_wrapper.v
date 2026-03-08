//Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2018.2 (win64) Build 2258646 Thu Jun 14 20:03:12 MDT 2018
//Date        : Sun Mar  8 17:35:12 2026
//Host        : DESKTOP-QOVO705 running 64-bit major release  (build 9200)
//Command     : generate_target clock_ip_wrapper.bd
//Design      : clock_ip_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module clock_ip_wrapper
   (clk_in1_n_0,
    clk_in1_p_0,
    clk_out1_0,
    resetn_0);
  input clk_in1_n_0;
  input clk_in1_p_0;
  output clk_out1_0;
  input resetn_0;

  wire clk_in1_n_0;
  wire clk_in1_p_0;
  wire clk_out1_0;
  wire resetn_0;

  clock_ip clock_ip_i
       (.clk_in1_n_0(clk_in1_n_0),
        .clk_in1_p_0(clk_in1_p_0),
        .clk_out1_0(clk_out1_0),
        .resetn_0(resetn_0));
endmodule

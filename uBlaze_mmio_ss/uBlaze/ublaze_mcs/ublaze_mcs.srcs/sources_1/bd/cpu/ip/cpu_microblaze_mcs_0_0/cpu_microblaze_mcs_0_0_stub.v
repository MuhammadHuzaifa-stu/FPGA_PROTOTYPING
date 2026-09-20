// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.1 (lin64) Build 2552052 Fri May 24 14:47:09 MDT 2019
// Date        : Sun Sep 20 15:16:15 2026
// Host        : m-huzaifa-IdeaPad-Flex-5-14ALC7 running 64-bit Ubuntu 26.04.1 LTS
// Command     : write_verilog -force -mode synth_stub
//               /home/m-huzaifa/projects/FPGA_PROTOTYPING/uBlaze_mmio_ss/uBlaze/ublaze_mcs/ublaze_mcs.srcs/sources_1/bd/cpu/ip/cpu_microblaze_mcs_0_0/cpu_microblaze_mcs_0_0_stub.v
// Design      : cpu_microblaze_mcs_0_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a35tfgg484-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "bd_de6f,Vivado 2018.2" *)
module cpu_microblaze_mcs_0_0(Clk, Reset, IO_addr_strobe, IO_address, 
  IO_byte_enable, IO_read_data, IO_read_strobe, IO_ready, IO_write_data, IO_write_strobe)
/* synthesis syn_black_box black_box_pad_pin="Clk,Reset,IO_addr_strobe,IO_address[31:0],IO_byte_enable[3:0],IO_read_data[31:0],IO_read_strobe,IO_ready,IO_write_data[31:0],IO_write_strobe" */;
  input Clk;
  input Reset;
  output IO_addr_strobe;
  output [31:0]IO_address;
  output [3:0]IO_byte_enable;
  input [31:0]IO_read_data;
  output IO_read_strobe;
  input IO_ready;
  output [31:0]IO_write_data;
  output IO_write_strobe;
endmodule

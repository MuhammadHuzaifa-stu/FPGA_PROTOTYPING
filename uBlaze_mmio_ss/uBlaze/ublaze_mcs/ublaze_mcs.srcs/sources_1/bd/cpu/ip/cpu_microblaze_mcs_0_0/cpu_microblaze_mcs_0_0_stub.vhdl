-- Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2018.2 (win64) Build 2258646 Thu Jun 14 20:03:12 MDT 2018
-- Date        : Mon Mar 16 10:05:11 2026
-- Host        : DESKTOP-QOVO705 running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               c:/FPGA_PROTOTYPING/Microblaze/uBlaze/ublaze_mcs/ublaze_mcs.srcs/sources_1/bd/cpu/ip/cpu_microblaze_mcs_0_0/cpu_microblaze_mcs_0_0_stub.vhdl
-- Design      : cpu_microblaze_mcs_0_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7a35tfgg484-2
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity cpu_microblaze_mcs_0_0 is
  Port ( 
    Clk : in STD_LOGIC;
    Reset : in STD_LOGIC;
    IO_addr_strobe : out STD_LOGIC;
    IO_address : out STD_LOGIC_VECTOR ( 31 downto 0 );
    IO_byte_enable : out STD_LOGIC_VECTOR ( 3 downto 0 );
    IO_read_data : in STD_LOGIC_VECTOR ( 31 downto 0 );
    IO_read_strobe : out STD_LOGIC;
    IO_ready : in STD_LOGIC;
    IO_write_data : out STD_LOGIC_VECTOR ( 31 downto 0 );
    IO_write_strobe : out STD_LOGIC
  );

end cpu_microblaze_mcs_0_0;

architecture stub of cpu_microblaze_mcs_0_0 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "Clk,Reset,IO_addr_strobe,IO_address[31:0],IO_byte_enable[3:0],IO_read_data[31:0],IO_read_strobe,IO_ready,IO_write_data[31:0],IO_write_strobe";
attribute X_CORE_INFO : string;
attribute X_CORE_INFO of stub : architecture is "bd_de6f,Vivado 2018.2";
begin
end;

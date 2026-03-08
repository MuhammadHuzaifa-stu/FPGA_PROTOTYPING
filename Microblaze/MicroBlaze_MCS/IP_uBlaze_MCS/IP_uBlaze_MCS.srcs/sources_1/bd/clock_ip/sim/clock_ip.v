//Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2018.2 (win64) Build 2258646 Thu Jun 14 20:03:12 MDT 2018
//Date        : Sun Mar  8 17:35:12 2026
//Host        : DESKTOP-QOVO705 running 64-bit major release  (build 9200)
//Command     : generate_target clock_ip.bd
//Design      : clock_ip
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CORE_GENERATION_INFO = "clock_ip,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=clock_ip,x_ipVersion=1.00.a,x_ipLanguage=VERILOG,numBlks=1,numReposBlks=1,numNonXlnxBlks=0,numHierBlks=0,maxHierDepth=0,numSysgenBlks=0,numHlsBlks=0,numHdlrefBlks=0,numPkgbdBlks=0,bdsource=USER,synth_mode=OOC_per_IP}" *) (* HW_HANDOFF = "clock_ip.hwdef" *) 
module clock_ip
   (clk_in1_n_0,
    clk_in1_p_0,
    clk_out1_0,
    resetn_0);
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.CLK_IN1_N_0 CLK" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.CLK_IN1_N_0, CLK_DOMAIN clock_ip_clk_in1_n_0, FREQ_HZ 100000000, PHASE 0.000" *) input clk_in1_n_0;
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.CLK_IN1_P_0 CLK" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.CLK_IN1_P_0, CLK_DOMAIN clock_ip_clk_in1_p_0, FREQ_HZ 100000000, PHASE 0.000" *) input clk_in1_p_0;
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.CLK_OUT1_0 CLK" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.CLK_OUT1_0, CLK_DOMAIN /clk_wiz_0_clk_out1, FREQ_HZ 100000000, PHASE 0.0" *) output clk_out1_0;
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST.RESETN_0 RST" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME RST.RESETN_0, POLARITY ACTIVE_LOW" *) input resetn_0;

  wire clk_in1_n_0_1;
  wire clk_in1_p_0_1;
  wire clk_wiz_0_clk_out1;
  wire resetn_0_1;

  assign clk_in1_n_0_1 = clk_in1_n_0;
  assign clk_in1_p_0_1 = clk_in1_p_0;
  assign clk_out1_0 = clk_wiz_0_clk_out1;
  assign resetn_0_1 = resetn_0;
  clock_ip_clk_wiz_0_0 clk_wiz_0
       (.clk_in1_n(clk_in1_n_0_1),
        .clk_in1_p(clk_in1_p_0_1),
        .clk_out1(clk_wiz_0_clk_out1),
        .resetn(resetn_0_1));
endmodule

// =========================================================================== //
// Author       : fengyangwu - ASR
// Last modified: 2020-07-09 15:14
// Filename     : tb_top.sv
// Description  : 
// =========================================================================== //
`ifndef TB_TOP_SV
`define TB_TOP_SV

`timescale 1ns/1ps

//common defines
`include "uvm_macros.svh" 

//top env defines
`include "nr_l2dl_env_define.svi"
`include "nr_l2dl_tb_top_define.svi"
`include "nr_l2dl_intf_define.svi"
`include "nr_l2dl_map_define.svi"

//common pkg
`include "asr_common_pkg.svi"
`include "env_common_pkg.svi"
`include "asr_src_fifo_pkg.svi"
`include "asr_dst_fifo_pkg.svi"
`include "regbus_pkg.sv"

//reuse pkg
`include "rx_mac_tb_cmd_pkg.svi"
`include "rx_mac_dma_pkg.svi"
`include "rx_mac_mce_pkg.svi"
`include "rx_mac_dl_node0_pkg.svi"
`include "rx_mac_env_pkg.svi"


//uvc agent pkg
`include "nr_l2dl_dtc_pld_pkg.svi"
`include "nr_l2dl_dtc_rdma_pkg.svi"

//top env pkg
`include "nr_l2dl_env_pkg.svi"

module tb_top;
    import uvm_pkg::*;


    import asr_common_pkg::*;
    import env_common_pkg::*;
    import regbus_pkg::*;
    import asr_src_fifo_pkg::*;
    import asr_dst_fifo_pkg::*;

    import rx_mac_tb_cmd_pkg::*;
    import rx_mac_dma_pkg::*;
    import rx_mac_mce_pkg::*;
    import rx_mac_dl_node0_pkg::*;
    import rx_mac_env_pkg::*;


    import nr_l2dl_dtc_pld_pkg::*;
    import nr_l2dl_dtc_rdma_pkg::*;
    import nr_l2dl_env_pkg::*;


    `include "nr_l2dl_test_include.svi"

    `NR_L2DL_DUT_CLK_RST_SRC(`HWTOP_HIER.dut);//TODO: clock frq:122.88*8=983.04

    
    `NR_L2DL_FSDB_DUMP_MACRO;

    initial begin
        for(int ii=`TB_IDX; ii<`TB_NUM+`TB_IDX+`TB_ADD; ii++)begin
            @(posedge `HWTOP_HIER.dut.l2mac_req);
            $readmemh($sformatf("%0d.dat",ii),`HWTOP_HIER.mac_memory);
        end
    end

    initial begin
        for(int ii=`TB_IDX; ii<`TB_NUM+`TB_IDX+`TB_ADD; ii++)begin
            if(ii != `TB_IDX)begin
                @(posedge `HWTOP_HIER.dut.l2dtc_done);
                $readmemh($sformatf("%0d.dat",ii),`HWTOP_HIER.dtc_memory);
            end else begin
                @(posedge `HWTOP_HIER.dut.l2dtc_req);
                $readmemh($sformatf("%0d.dat",ii),`HWTOP_HIER.dtc_memory);
            end
        end
    end

    initial begin
       `uvm_info("tb_top", $sformatf("tb_top interface setup begin"),UVM_LOW);         
        $system("rm *.bin");
        $system("rm *.dat");

       `NR_L2DL_L1_CFG_IF_TB(`HWTOP_HIER.nr_l2dl_l1_cfg_if, "env.l1_reg_agent")
       `NR_L2DL_L2_CFG_IF_TB(`HWTOP_HIER.nr_l2dl_l2_cfg_if, "env.l2_reg_agent")
       `NR_L2DL_L2_CFG_IF_TB(`HWTOP_HIER.nr_l2dl_l2_cfg_if, "env.l2_blkaddr_agent")
       `NR_L2DL_TB_CMD_IF_TB(`HWTOP_HIER.nr_l2dl_tb_cmd_if, "env.m_nr_l2dl_tb_cmd_agent")

       //------------------reuse   mac----------------------------------
       //`RX_MAC_DMA_CFG_IF_TB(`HWTOP_HIER.rx_mac_dma_cfg_if, "env*")

       `NR_L2DL_TB_CMD_IF_TB(`HWTOP_HIER.nr_l2dl_tb_cmd_if, "env.m_rx_mac_env.m_rx_mac_tb_cmd_agent")
       `RX_MAC_L1_MCE_IF_TB(`HWTOP_HIER.rx_mac_l1_mce_if, "env.m_rx_mac_env.m_rx_mac_l1_mce_agent")
       `RX_MAC_L2_MCE_IF_TB(`HWTOP_HIER.rx_mac_l2_mce_if, "env.m_rx_mac_env.m_rx_mac_l2_mce_agent")
       `RX_MAC_DL_NODE0_IF_TB(`HWTOP_HIER.rx_mac_dl_node0_if, "env.m_rx_mac_env.m_rx_mac_dl_node0_agent")
       `RX_MAC_DMA_IF_TB(`HWTOP_HIER.rx_mac_dma_if, "env.m_rx_mac_env.m_rx_mac_dma_agent")
       `RX_MAC_DTC_CMD_IF_TB(`HWTOP_HIER.rx_mac_dtc_cmd_if, "env.m_rx_mac_env*")
       `RX_MAC_TOP_IF_TB(`HWTOP_HIER.rx_mac_top_if, "uvm_test_top*")
       //---------------------------------------------------------------------------------------------

       `RX_MAC_DMA_IF_TB(`HWTOP_HIER.rx_mac_dma_if, "env.m_nr_l2dl_mac_dma_agent")
       //`RX_MAC_DMA_IF_TB(`HWTOP_HIER.nr_l2dl_mac_l2mce_dma_if, "env.m_nr_l2dl_mac_l2mce_dma_agent")
       //`RX_MAC_DMA_IF_TB(`HWTOP_HIER.nr_l2dl_mac_l1tbinfo_dma_if, "env.m_nr_l2dl_mac_l1tbinfo_dma_agent")
       //`RX_MAC_DMA_IF_TB(`HWTOP_HIER.nr_l2dl_mac_l2tbinfo_dma_if, "env.m_nr_l2dl_mac_l2tbinfo_dma_agent")
       `RX_MAC_DMA_IF_TB(`HWTOP_HIER.nr_l2dl_dtc_dma_if, "env.m_nr_l2dl_dtc_dma_agent")

       `NR_L2DL_DTC_PLD_IF_TB(`HWTOP_HIER.nr_l2dl_dtc_pld_if, "env.m_nr_l2dl_dtc_pld_agent")
       `NR_L2DL_DTC_RDMA_IF_TB(`HWTOP_HIER.nr_l2dl_dtc_rdma_if, "env.m_nr_l2dl_dtc_rdma_agent")

       `NR_L2DL_TOP_IF_TB(`HWTOP_HIER.nr_l2dl_top_if, "uvm_test_top*")

       `uvm_info("tb_top", $sformatf("tb_top interface setup end"),UVM_LOW);         

       $timeformat(-9, 1, "ns", 10);
       run_test();
    end
endmodule: tb_top

`endif


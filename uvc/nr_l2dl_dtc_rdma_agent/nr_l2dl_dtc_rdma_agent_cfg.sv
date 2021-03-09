// =========================================================================== //
// Author       : fengyang.wu - ASR
// Last modified: 2020-07-10 18:47
// Filename     : nr_l2dl_dtc_rdma_agent_cfg.sv
// Description  : 
// =========================================================================== //
`ifndef NR_L2DL_DTC_RDMA_AGENT_CFG__SV
`define NR_L2DL_DTC_RDMA_AGENT_CFG__SV

class nr_l2dl_dtc_rdma_agent_cfg extends uvm_object;
    NR_L2DL_SCB_STREAM_ID_T stream_id0;
    NR_L2DL_SCB_STREAM_ID_T stream_id1;
    NR_L2DL_SCB_STREAM_ID_T stream_id2;
    NR_L2DL_SCB_STREAM_ID_T stream_id3;
    NR_L2DL_SCB_STREAM_ID_T stream_id4;
    NR_L2DL_SCB_STREAM_ID_T stream_id5;
    NR_L2DL_SCB_STREAM_ID_T stream_id6;
    NR_L2DL_SCB_STREAM_ID_T stream_id7;
    NR_L2DL_SCB_STREAM_ID_T stream_id8;

    uvm_active_passive_enum is_active = UVM_ACTIVE;   
    bit    checks_enable        = 1;
    bit    coverage_enable      = 1;
    bit    drv_timeout_chk      = 1;
    int    drv_timeout_ns       = 1000_0000;
    bit    drv_busy             = 0;  //for end of test objection
    bit    mon_busy             = 0;  //for end of test objection
    bit    transformer_enable   = 1;

    bit    timeout_en =1;

    int unsigned     data_width;
    int unsigned     ch_id;

    rand int    seq_item_cnt;

    constraint seq_item_cnt_vld {
        seq_item_cnt inside {[1:100]};
    }
   
    int unsigned  req_interval_min=1;
    int unsigned  req_interval_max=10;
     //l1 reg
    bit [31:0]  tb_info1_dma_addr;  
    bit [7:0]   tb_info1_space;
    bit [31:0]  macce_node1_dma_addr;
    bit [7:0]   macce_node1_space;
    //l2 reg
    bit [31:0]  tb_info2_dma_addr;
    bit [7:0]   tb_info2_space;
    bit [31:0]  macce_node2_dma_addr;
    bit [7:0]   macce_node2_space;
    bit [31:0]  macce_pld_addr;
    bit [15:0]  macce_pld_space;
    bit [31:0]  acc_node_dma_addr;
    bit [15:0]  acc_node_space;
    bit [31:0]  dl_node0_dma_addr;
    bit [15:0]  dl_node0_space;
    bit [31:0]  dl_node1_dma_addr;
    bit [29:0]  dl_node1_space;
    bit [31:0]  dbg_out_addr;
    bit [15:0]  dbg_out_space;

    int unsigned blkaddr_pool_size;

    nr_l2dl_lc_cfg  lc_cfg[`RX_MAC_ENTITY_NUM];

   
   `uvm_object_utils_begin(nr_l2dl_dtc_rdma_agent_cfg)
       `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_DEFAULT)
       `uvm_field_int(data_width, UVM_DEFAULT)
       `uvm_field_int(coverage_enable, UVM_DEFAULT)
       `uvm_field_int(drv_timeout_chk, UVM_DEFAULT)
       `uvm_field_int(drv_timeout_ns, UVM_DEFAULT)
       `uvm_field_int(seq_item_cnt, UVM_DEFAULT)
       `uvm_field_int(drv_busy, UVM_DEFAULT)
       `uvm_field_int(mon_busy, UVM_DEFAULT)
       `uvm_field_int(macce_node1_dma_addr, UVM_DEFAULT)
       `uvm_field_int(macce_node1_space, UVM_DEFAULT)
       `uvm_field_int(tb_info1_dma_addr, UVM_DEFAULT)  
       `uvm_field_int(tb_info1_space, UVM_DEFAULT)
       `uvm_field_int(dbg_out_addr, UVM_DEFAULT)
       `uvm_field_int(dbg_out_space, UVM_DEFAULT)
       `uvm_field_int(acc_node_space, UVM_DEFAULT)
       `uvm_field_int(dl_node0_space, UVM_DEFAULT)
       `uvm_field_int(dl_node1_space, UVM_DEFAULT)
       `uvm_field_int(tb_info2_space, UVM_DEFAULT)
       `uvm_field_int(macce_node2_space, UVM_DEFAULT)
       `uvm_field_int(macce_pld_space, UVM_DEFAULT)
       `uvm_field_int(macce_pld_addr, UVM_DEFAULT)
       `uvm_field_int(dl_node0_dma_addr, UVM_DEFAULT)
       `uvm_field_int(dl_node1_dma_addr, UVM_DEFAULT)
       `uvm_field_int(acc_node_dma_addr, UVM_DEFAULT)
       `uvm_field_int(macce_node2_dma_addr, UVM_DEFAULT)
       `uvm_field_int(tb_info2_dma_addr, UVM_DEFAULT)
       `uvm_field_int(blkaddr_pool_size, UVM_DEFAULT)
   `uvm_object_utils_end

   function new (string name = "nr_l2dl_dtc_rdma_agent_cfg");
       super.new(name);
   endfunction

endclass: nr_l2dl_dtc_rdma_agent_cfg

`endif


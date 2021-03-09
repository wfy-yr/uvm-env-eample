// =========================================================================== //
// Author       : fengyangwu - ASR
// Last modified: 2020-07-09 9:49
// Filename     : nr_l2dl_env_cfg.sv
// Description  : 
// =========================================================================== //
`ifndef NR_L2DL_ENV_CFG_SV
`define NR_L2DL_ENV_CFG_SV

typedef class nr_l2dl_ddr_mem_policy;
typedef class uvm_virtual_reg_model;

class nr_l2dl_env_cfg extends uvm_object;

   bit                    l1_reg_agent_en;
   bit                    l2_reg_agent_en;
   bit                    l2_blkaddr_agent_en;
   bit                    nr_l2dl_tb_cmd_agent_en;
   //bit                    nr_l2dl_l1_mce_agent_en;
   //bit                    nr_l2dl_l2_mce_agent_en;
   //bit                    nr_l2dl_dl_node0_agent_en;
   bit                    nr_l2dl_dtc_dma_agent_en;
   bit                    nr_l2dl_mac_dma_agent_en;
   bit                    nr_l2dl_dtc_pld_agent_en;
   bit                    nr_l2dl_dtc_rdma_agent_en;
   //bit                    nr_l2dl_mac_l2mce_dma_agent_en;
   //bit                    nr_l2dl_mac_l1tbinfo_dma_agent_en;
   //bit                    nr_l2dl_mac_l2tbinfo_dma_agent_en;
   //bit                    nr_l2dl_dtc_cmd_agent_en;
   bit                    rx_mac_env_en;
   bit                    scb_en;
   bit                    ref_model_en;
   bit                    scb_conn_en;
   bit                    ref_model_conn_en;

   rx_mac_env_cfg                 m_rx_mac_env_cfg;

   rand rx_mac_reg_cfg            m_rx_mac_reg_cfg;

   rand rx_mac_dl_node0_pkt_cfg   normal_pkt_cfg[200];

   rand nr_l2dl_mce_cfg           mce_cfg[31];

   rand nr_l2dl_lc_cfg             lc_cfg[`RX_MAC_ENTITY_NUM];

   rand rx_mac_tb_cmd_agent_cfg       m_nr_l2dl_tb_cmd_agent_cfg;

   //rand nr_l2dl_mce_agent_cfg          m_nr_l2dl_l1_mce_agent_cfg;

   //rand nr_l2dl_mce_agent_cfg          m_nr_l2dl_l2_mce_agent_cfg;

   //rand nr_l2dl_dl_node0_agent_cfg     m_nr_l2dl_dl_node0_agent_cfg;

   rand rx_mac_dma_agent_cfg          m_nr_l2dl_dtc_dma_agent_cfg;
   rand rx_mac_dma_agent_cfg          m_nr_l2dl_mac_dma_agent_cfg;
   rand nr_l2dl_dtc_pld_agent_cfg     m_nr_l2dl_dtc_pld_agent_cfg;
   rand nr_l2dl_dtc_rdma_agent_cfg    m_nr_l2dl_dtc_rdma_agent_cfg;
   //rand rx_mac_dma_agent_cfg          m_nr_l2dl_mac_l2mce_dma_agent_cfg;
   //rand rx_mac_dma_agent_cfg          m_nr_l2dl_mac_l1tbinfo_dma_agent_cfg;
   //rand rx_mac_dma_agent_cfg          m_nr_l2dl_mac_l2tbinfo_dma_agent_cfg;

   //rand nr_l2dl_dst_fifo_agent_cfg     m_nr_l2dl_dtc_cmd_agent_cfg;
   //mem_base is used as address offset between mem address(real or virtual) and AMBA address
   //for eg : AXI see 'h8000_0000 as are & DDR/AXI SLV see 0 as base
   //then set m_axi_bridge_env_cfg.a3s_mem_base = 'h8000_0000
   //typically it is 0
   uvm_mem ddr_mem;
   uvm_mem_mam_policy ddr_mem_policy;
   uvm_mem_mam_policy seg_info_block_policy;
   uvm_reg_map        ddr_mem_map;
   uvm_reg_addr_t     ddr_mem_base; // base addr of virtual mem, default 0

   rand  int    seq_item_cnt;
   bit          lc_cfg_exist_err_en='h0;
   bit          rb_cfg_exist_err_en='h0;
   int          subpdu_num_for_tb_min=10;
   int          subpdu_num_for_tb_max=100;
   bit  [7:0]   memory[];

   //l1 reg
   bit [31:0]  tb_info1_dma_addr=32'h0;  
   bit [7:0]   tb_info1_space=8'h8;
   bit [31:0]  macce_node1_dma_addr=32'h100;
   bit [7:0]   macce_node1_space=8'h30;
   //l2 reg
   bit [31:0]  tb_info2_dma_addr=32'h420;
   bit [7:0]   tb_info2_space=8'h8;
   bit [31:0]  macce_node2_dma_addr=32'h560;
   bit [7:0]   macce_node2_space=8'h30;
   bit [31:0]  macce_pld_addr=32'h880;
   bit [15:0]  macce_pld_space=16'hfff;
   bit [31:0]  acc_node_dma_addr=32'h10880;
   bit [15:0]  acc_node_space=16'h3e0;
   bit [31:0]  dl_node0_dma_addr=32'h18580;
   bit [15:0]  dl_node0_space=16'h240;
   bit [31:0]  dl_node1_dma_addr=32'h27f80;
   bit [29:0]  dl_node1_space=30'h3e0;
   bit [31:0]  dbg_out_addr=32'h29ec0;
   bit [15:0]  dbg_out_space=16'hff;

   bit [ 1:0]  cellgroup=1;
   bit [ 4:0]  cellindex=1;
   bit [11:0]  cursfn=1;
   bit [ 3:0]  cursubsfn=1;
   bit [ 4:0]  harqid=1;
   bit [ 2:0]  scs=1;


   //cmodel cfg
   rand int        normal_node_num;
   rand int        mce_num;
   rand int        err_num;
   rand int        padding_num;
   rand int        continuous_data_num;
   int             tb_size[];
   rand int        tb_index;


   rand bit [127:0] key_enc[`RX_MAC_ENTITY_NUM];
   rand bit [127:0] key_int[`RX_MAC_ENTITY_NUM];

   rand bit [31:0]  rx_deliv[`RX_MAC_ENTITY_NUM];

   //blk addr fifo
   int unsigned blkaddr_pool_size=2048;

   constraint seq_item_cnt_vld{
       seq_item_cnt inside {[1:511]};
   }

   `uvm_object_utils_begin(nr_l2dl_env_cfg)
       `uvm_field_object(m_rx_mac_reg_cfg, UVM_DEFAULT)
       `uvm_field_object(m_rx_mac_env_cfg, UVM_DEFAULT)
       `uvm_field_object(m_nr_l2dl_tb_cmd_agent_cfg, UVM_DEFAULT)
       //`uvm_field_object(m_nr_l2dl_l1_mce_agent_cfg, UVM_DEFAULT)
       //`uvm_field_object(m_nr_l2dl_l2_mce_agent_cfg, UVM_DEFAULT)
       //`uvm_field_object(m_nr_l2dl_dl_node0_agent_cfg, UVM_DEFAULT)
       `uvm_field_object(m_nr_l2dl_dtc_dma_agent_cfg, UVM_DEFAULT)
       `uvm_field_object(m_nr_l2dl_mac_dma_agent_cfg, UVM_DEFAULT)
       `uvm_field_object(m_nr_l2dl_dtc_pld_agent_cfg, UVM_DEFAULT)
       `uvm_field_object(m_nr_l2dl_dtc_rdma_agent_cfg, UVM_DEFAULT)
       //`uvm_field_object(m_nr_l2dl_mac_l2mce_dma_agent_cfg, UVM_DEFAULT)
       //`uvm_field_object(m_nr_l2dl_mac_l1tbinfo_dma_agent_cfg, UVM_DEFAULT)
       //`uvm_field_object(m_nr_l2dl_mac_l2tbinfo_dma_agent_cfg, UVM_DEFAULT)
       //`uvm_field_object(m_nr_l2dl_dtc_cmd_agent_cfg, UVM_DEFAULT)
       //`uvm_field_int(amba_env_en, UVM_DEFAULT)
       `uvm_field_int(seq_item_cnt, UVM_DEFAULT)
       `uvm_field_int(lc_cfg_exist_err_en, UVM_DEFAULT)
       `uvm_field_int(rb_cfg_exist_err_en, UVM_DEFAULT)
       `uvm_field_int(subpdu_num_for_tb_min, UVM_DEFAULT)
       `uvm_field_int(subpdu_num_for_tb_max, UVM_DEFAULT)
       `uvm_field_int(nr_l2dl_tb_cmd_agent_en, UVM_DEFAULT)
       //`uvm_field_int(nr_l2dl_l1_mce_agent_en, UVM_DEFAULT)
       //`uvm_field_int(nr_l2dl_l2_mce_agent_en, UVM_DEFAULT)
       //`uvm_field_int(nr_l2dl_dl_node0_agent_en, UVM_DEFAULT)
       `uvm_field_int(nr_l2dl_dtc_dma_agent_en, UVM_DEFAULT)
       `uvm_field_int(nr_l2dl_mac_dma_agent_en, UVM_DEFAULT)
       `uvm_field_int(nr_l2dl_dtc_pld_agent_en, UVM_DEFAULT)
       `uvm_field_int(nr_l2dl_dtc_rdma_agent_en, UVM_DEFAULT)
       //`uvm_field_int(nr_l2dl_mac_l2mce_dma_agent_en, UVM_DEFAULT)
       //`uvm_field_int(nr_l2dl_mac_l1tbinfo_dma_agent_en, UVM_DEFAULT)
       //`uvm_field_int(nr_l2dl_mac_l2tbinfo_dma_agent_en, UVM_DEFAULT)
       //`uvm_field_int(nr_l2dl_dtc_cmd_agent_en, UVM_DEFAULT)
       `uvm_field_int(l1_reg_agent_en, UVM_DEFAULT)
       `uvm_field_int(l2_reg_agent_en, UVM_DEFAULT)
       `uvm_field_int(l2_blkaddr_agent_en, UVM_DEFAULT)
       `uvm_field_int(rx_mac_env_en, UVM_DEFAULT)
       `uvm_field_int(scb_en, UVM_DEFAULT)
       `uvm_field_int(ref_model_en, UVM_DEFAULT)
       `uvm_field_int(scb_conn_en, UVM_DEFAULT)
       `uvm_field_int(ref_model_conn_en, UVM_DEFAULT)
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
       `uvm_field_sarray_int(key_enc, UVM_DEFAULT)
       `uvm_field_sarray_int(key_int, UVM_DEFAULT)
       `uvm_field_sarray_int(rx_deliv, UVM_DEFAULT)
       `uvm_field_int(blkaddr_pool_size, UVM_DEFAULT)
       `uvm_field_int(tb_index, UVM_DEFAULT)
   `uvm_object_utils_end                   

   //new

   extern function new(string name = "nr_l2dl_env_cfg");
   extern virtual function void gen_virtual_mem();
   extern virtual function void mode_set();
   
endclass: nr_l2dl_env_cfg

function nr_l2dl_env_cfg::new(string name = "nr_l2dl_env_cfg"); //{{{
      super.new(name);
      m_rx_mac_reg_cfg = rx_mac_reg_cfg::type_id::create("m_rx_mac_reg_cfg");
      m_rx_mac_env_cfg = rx_mac_env_cfg::type_id::create("m_rx_mac_env_cfg");

      m_nr_l2dl_tb_cmd_agent_cfg = rx_mac_tb_cmd_agent_cfg::type_id::create("m_nr_l2dl_tb_cmd_agent_cfg");
      //m_nr_l2dl_l1_mce_agent_cfg = nr_l2dl_mce_agent_cfg::type_id::create("m_nr_l2dl_l1_mce_agent_cfg");
      //m_nr_l2dl_l2_mce_agent_cfg = nr_l2dl_mce_agent_cfg::type_id::create("m_nr_l2dl_l2_mce_agent_cfg");
      //m_nr_l2dl_dl_node0_agent_cfg = nr_l2dl_dl_node0_agent_cfg::type_id::create("m_nr_l2dl_dl_node0_agent_cfg");
      m_nr_l2dl_dtc_dma_agent_cfg = rx_mac_dma_agent_cfg::type_id::create("m_nr_l2dl_dtc_dma_agent_cfg");
      m_nr_l2dl_mac_dma_agent_cfg = rx_mac_dma_agent_cfg::type_id::create("m_nr_l2dl_mac_dma_agent_cfg");
      m_nr_l2dl_dtc_pld_agent_cfg = nr_l2dl_dtc_pld_agent_cfg::type_id::create("m_nr_l2dl_dtc_pld_agent_cfg");
      m_nr_l2dl_dtc_rdma_agent_cfg = nr_l2dl_dtc_rdma_agent_cfg::type_id::create("m_nr_l2dl_dtc_rdma_agent_cfg");
      //m_nr_l2dl_mac_l2mce_dma_agent_cfg = rx_mac_dma_agent_cfg::type_id::create("m_nr_l2dl_mac_l2mce_dma_agent_cfg");
      //m_nr_l2dl_mac_l1tbinfo_dma_agent_cfg = rx_mac_dma_agent_cfg::type_id::create("m_nr_l2dl_mac_l1tbinfo_dma_agent_cfg");
      //m_nr_l2dl_mac_l2tbinfo_dma_agent_cfg = rx_mac_dma_agent_cfg::type_id::create("m_nr_l2dl_mac_l2tbinfo_dma_agent_cfg");
      //m_nr_l2dl_dtc_cmd_agent_cfg = nr_l2dl_dst_fifo_agent_cfg::type_id::create("m_nr_l2dl_dtc_cmd_agent_cfg");

      gen_virtual_mem();

      foreach(lc_cfg[ii]) begin
          lc_cfg[ii] = nr_l2dl_lc_cfg::type_id::create($sformatf("lc_cfg[%0d]", ii));
      end

      memory  = new[100000000000];
      tb_size = new[`TB_IDX+`TB_NUM+`TB_ADD];

endfunction: new //}}}

function void nr_l2dl_env_cfg::mode_set(); //{{{
    begin
        rx_mac_env_en     = 1;
        scb_en            = 1;
        ref_model_en      = 1;
        scb_conn_en       = 1;
        ref_model_conn_en = 1;
        l1_reg_agent_en = 1;
        l2_reg_agent_en = 1;
        l2_blkaddr_agent_en = 1;
        nr_l2dl_tb_cmd_agent_en = 1;
        m_nr_l2dl_tb_cmd_agent_cfg.is_active = UVM_ACTIVE;

        nr_l2dl_dtc_dma_agent_en = 0;
        m_nr_l2dl_dtc_dma_agent_cfg.is_active = UVM_ACTIVE;
        
        nr_l2dl_mac_dma_agent_en = 0;
        m_nr_l2dl_mac_dma_agent_cfg.is_active = UVM_ACTIVE;
        //m_nr_l2dl_mac_dlnode0_dma_agent_cfg.mon_mode  = rx_mac_dma_agent_cfg::DMA_DL_NODE0;
        m_nr_l2dl_mac_dma_agent_cfg.stream_id0 = DMA_DL_NODE0;
        m_nr_l2dl_mac_dma_agent_cfg.stream_id1 = DMA_L1_MCE_NODE;
        m_nr_l2dl_mac_dma_agent_cfg.stream_id2 = DMA_L2_MCE_NODE;
        m_nr_l2dl_mac_dma_agent_cfg.stream_id3 = DMA_L1_TB_INFO;
        m_nr_l2dl_mac_dma_agent_cfg.stream_id4 = DMA_L2_TB_INFO;
        m_nr_l2dl_mac_dma_agent_cfg.stream_id5 = DMA_DL_NODE0_PLD;
        m_nr_l2dl_mac_dma_agent_cfg.stream_id6 = DMA_L1_MCE_PLD;
        m_nr_l2dl_mac_dma_agent_cfg.stream_id7 = DMA_L2_MCE_PLD;
        m_nr_l2dl_mac_dma_agent_cfg.stream_id8 = DMA_ACC_NODE;

        nr_l2dl_dtc_pld_agent_en = 1;
        m_nr_l2dl_dtc_pld_agent_cfg.is_active = UVM_PASSIVE;
        m_nr_l2dl_dtc_pld_agent_cfg.stream_id = DTC_PLD;

        nr_l2dl_dtc_rdma_agent_en = 1;
        m_nr_l2dl_dtc_rdma_agent_cfg.is_active = UVM_PASSIVE;
        m_nr_l2dl_dtc_rdma_agent_cfg.stream_id0 = TB_INFO1_DMA;
        m_nr_l2dl_dtc_rdma_agent_cfg.stream_id1 = TB_INFO2_DMA;
        m_nr_l2dl_dtc_rdma_agent_cfg.stream_id2 = MCE_NODE1_DMA;
        m_nr_l2dl_dtc_rdma_agent_cfg.stream_id3 = MCE_NODE2_DMA;
        m_nr_l2dl_dtc_rdma_agent_cfg.stream_id4 = MCE_PLD_DMA;
        m_nr_l2dl_dtc_rdma_agent_cfg.stream_id5 = DL_NODE0_DMA;
        m_nr_l2dl_dtc_rdma_agent_cfg.stream_id6 = DL_NODE0_PLD_DMA;
        m_nr_l2dl_dtc_rdma_agent_cfg.stream_id7 = ACC_NODE_DMA;
        m_nr_l2dl_dtc_rdma_agent_cfg.stream_id8 = DL_NODE0_ACC;
        m_nr_l2dl_dtc_rdma_agent_cfg.tb_info1_dma_addr     = tb_info1_dma_addr;  
        m_nr_l2dl_dtc_rdma_agent_cfg.tb_info1_space        = tb_info1_space;
        m_nr_l2dl_dtc_rdma_agent_cfg.macce_node1_dma_addr  = macce_node1_dma_addr;
        m_nr_l2dl_dtc_rdma_agent_cfg.macce_node1_space     = macce_node1_space;
        m_nr_l2dl_dtc_rdma_agent_cfg.tb_info2_dma_addr     = tb_info2_dma_addr;
        m_nr_l2dl_dtc_rdma_agent_cfg.tb_info2_space        = tb_info2_space;
        m_nr_l2dl_dtc_rdma_agent_cfg.macce_node2_dma_addr  = macce_node2_dma_addr;
        m_nr_l2dl_dtc_rdma_agent_cfg.macce_node2_space     = macce_node2_space;
        m_nr_l2dl_dtc_rdma_agent_cfg.macce_pld_addr        = macce_pld_addr;
        m_nr_l2dl_dtc_rdma_agent_cfg.macce_pld_space       = macce_pld_space;
        m_nr_l2dl_dtc_rdma_agent_cfg.acc_node_dma_addr     = acc_node_dma_addr;
        m_nr_l2dl_dtc_rdma_agent_cfg.acc_node_space        = acc_node_space;
        m_nr_l2dl_dtc_rdma_agent_cfg.dl_node0_dma_addr     = dl_node0_dma_addr;
        m_nr_l2dl_dtc_rdma_agent_cfg.dl_node0_space        = dl_node0_space;
        m_nr_l2dl_dtc_rdma_agent_cfg.dl_node1_dma_addr     = dl_node1_dma_addr;
        m_nr_l2dl_dtc_rdma_agent_cfg.dl_node1_space        = dl_node1_space;
        m_nr_l2dl_dtc_rdma_agent_cfg.dbg_out_addr          = dbg_out_addr;
        m_nr_l2dl_dtc_rdma_agent_cfg.dbg_out_space         = dbg_out_space;
        m_nr_l2dl_dtc_rdma_agent_cfg.blkaddr_pool_size     = blkaddr_pool_size;
        for(int ii=0; ii<`RX_MAC_ENTITY_NUM; ii++)begin
            m_nr_l2dl_dtc_rdma_agent_cfg.lc_cfg[ii]         = lc_cfg[ii];
        end
        //nr_l2dl_mac_l2mce_dma_agent_en = 1;
        //m_nr_l2dl_mac_l2mce_dma_agent_cfg.is_active = UVM_PASSIVE;
        //m_nr_l2dl_mac_l2mce_dma_agent_cfg.mon_mode  = rx_mac_dma_agent_cfg::DMA_L2_MCE_NODE;
        //m_nr_l2dl_mac_l2mce_dma_agent_cfg.stream_id = DMA_L2_MCE_NODE;

        //nr_l2dl_mac_l1tbinfo_dma_agent_en = 1;
        //m_nr_l2dl_mac_l1tbinfo_dma_agent_cfg.is_active = UVM_PASSIVE;
        //m_nr_l2dl_mac_l1tbinfo_dma_agent_cfg.mon_mode  = rx_mac_dma_agent_cfg::DMA_L1_TB_INFO;
        //m_nr_l2dl_mac_l1tbinfo_dma_agent_cfg.stream_id = DMA_L1_TB_INFO;

        //nr_l2dl_mac_l2tbinfo_dma_agent_en = 1;
        //m_nr_l2dl_mac_l2tbinfo_dma_agent_cfg.is_active = UVM_PASSIVE;
        //m_nr_l2dl_mac_l2tbinfo_dma_agent_cfg.mon_mode  = rx_mac_dma_agent_cfg::DMA_L2_TB_INFO;
        //m_nr_l2dl_mac_l2tbinfo_dma_agent_cfg.stream_id = DMA_L2_TB_INFO;
        //-----------------------rx mac reuse-------------------------//
        m_rx_mac_env_cfg.scb_en            = 1;
        m_rx_mac_env_cfg.ref_model_en      = 1;
        m_rx_mac_env_cfg.scb_conn_en       = 1;
        m_rx_mac_env_cfg.ref_model_conn_en = 1;
        m_rx_mac_env_cfg.l1_reg_agent_en = 0;
        m_rx_mac_env_cfg.l2_reg_agent_en = 0;
        m_rx_mac_env_cfg.rx_mac_tb_cmd_agent_en = 0;
        m_rx_mac_env_cfg.m_rx_mac_tb_cmd_agent_cfg.is_active = UVM_PASSIVE;

        m_rx_mac_env_cfg.rx_mac_l1_mce_agent_en = 1;
        m_rx_mac_env_cfg.m_rx_mac_l1_mce_agent_cfg.is_active = UVM_PASSIVE;
        m_rx_mac_env_cfg.m_rx_mac_l1_mce_agent_cfg.stream_id = L1_MCE_NODE;

        m_rx_mac_env_cfg.rx_mac_l2_mce_agent_en = 1;
        m_rx_mac_env_cfg.m_rx_mac_l2_mce_agent_cfg.is_active = UVM_PASSIVE;
        m_rx_mac_env_cfg.m_rx_mac_l2_mce_agent_cfg.stream_id = L2_MCE_NODE;

        m_rx_mac_env_cfg.rx_mac_dl_node0_agent_en = 1;
        m_rx_mac_env_cfg.m_rx_mac_dl_node0_agent_cfg.is_active = UVM_PASSIVE;
        m_rx_mac_env_cfg.m_rx_mac_dl_node0_agent_cfg.stream_id = DL_NODE0;

        m_rx_mac_env_cfg.rx_mac_tb_cmd_agent_en = 1;
        m_rx_mac_env_cfg.m_rx_mac_tb_cmd_agent_cfg.is_active = UVM_PASSIVE;

        m_rx_mac_env_cfg.rx_mac_dma_agent_en = 0;
        m_rx_mac_env_cfg.m_rx_mac_dma_agent_cfg.is_active = UVM_PASSIVE;

        m_rx_mac_env_cfg.rx_mac_dtc_cmd_agent_en = 0;
        m_rx_mac_env_cfg.m_rx_mac_dtc_cmd_agent_cfg.master_mode = 0;
        m_rx_mac_env_cfg.m_rx_mac_dtc_cmd_agent_cfg.is_active = UVM_PASSIVE;
        //--------------------------------------------------------------------//

        m_rx_mac_env_cfg.tb_info1_dma_addr     = tb_info1_dma_addr;  
        m_rx_mac_env_cfg.tb_info1_space        = tb_info1_space;
        m_rx_mac_env_cfg.macce_node1_dma_addr  = macce_node1_dma_addr;
        m_rx_mac_env_cfg.macce_node1_space     = macce_node1_space;
        m_rx_mac_env_cfg.tb_info2_dma_addr     = tb_info2_dma_addr;
        m_rx_mac_env_cfg.tb_info2_space        = tb_info2_space;
        m_rx_mac_env_cfg.macce_node2_dma_addr  = macce_node2_dma_addr;
        m_rx_mac_env_cfg.macce_node2_space     = macce_node2_space;
        m_rx_mac_env_cfg.macce_pld_addr        = macce_pld_addr;
        m_rx_mac_env_cfg.macce_pld_space       = macce_pld_space;
        m_rx_mac_env_cfg.acc_node_dma_addr     = acc_node_dma_addr;
        m_rx_mac_env_cfg.acc_node_space        = acc_node_space;
        m_rx_mac_env_cfg.dl_node0_dma_addr     = dl_node0_dma_addr;
        m_rx_mac_env_cfg.dl_node0_space        = dl_node0_space;
        m_rx_mac_env_cfg.dl_node1_dma_addr     = dl_node1_dma_addr;
        m_rx_mac_env_cfg.dl_node1_space        = dl_node1_space;
        m_rx_mac_env_cfg.dbg_out_addr          = dbg_out_addr;
        m_rx_mac_env_cfg.dbg_out_space         = dbg_out_space;

        for(int ii=0; ii<`RX_MAC_ENTITY_NUM; ii++)begin
            m_rx_mac_env_cfg.lc_cfg[ii]         = lc_cfg[ii];
        end
    end 
endfunction: mode_set //}}}

function void nr_l2dl_env_cfg::gen_virtual_mem(); //{{{
    nr_l2dl_ddr_mem_backdoor ddr_mem_bkdr;
    nr_l2dl_ddr_mem_policy ddr_mem_policy;
    uvm_virtual_reg_model virtual_block = new("virtual_block");
    virtual_block.build(); 
    ddr_mem = new("ddr_mem", 33'h10000_0000, 8.0);
    ddr_mem_bkdr = nr_l2dl_ddr_mem_backdoor::type_id::create("ddr_mem_bkdr", , this.get_full_name());
    ddr_mem_policy = new;
    ddr_mem_map = uvm_reg_map::backdoor();
    this.ddr_mem_policy = ddr_mem_policy;
    this.seg_info_block_policy = ddr_mem_policy;
    ddr_mem_bkdr.env_cfg = this;
    ddr_mem.set_backdoor(ddr_mem_bkdr);
    ddr_mem.configure(virtual_block);
    ddr_mem.add_map(ddr_mem_map);
endfunction: gen_virtual_mem // }}}

class nr_l2dl_ddr_mem_policy extends uvm_mem_mam_policy;// {{{ 
    constraint c_addr_4b {
    	 start_offset[5:0] == 0;
    	 start_offset[29:19] != 0;
    	 start_offset[31:30] == 0;
    }
endclass : nr_l2dl_ddr_mem_policy //}}}

class uvm_virtual_reg_model extends uvm_reg_block;// {{{ 
    virtual function void build();
        // address space
        this.default_map = create_map("default_map", 0, 8, UVM_LITTLE_ENDIAN, 0);
    endfunction : build
    
   `uvm_object_utils(uvm_virtual_reg_model)
   function new(input string name = "uvm_virtual_reg_model");
         super.new(name, UVM_NO_COVERAGE);
   endfunction
endclass : uvm_virtual_reg_model //}}}
`endif


// =========================================================================== //
// Author       : fengyang.wu - ASR
// Last modified: 2020-07-10 11:00
// Filename     : nr_l2dl_l2_cfg_seq.sv
// Description  : 
// =========================================================================== //
`ifndef NR_L2DL_L2_CFG_SEQ__SV
`define NR_L2DL_L2_CFG_SEQ__SV

class nr_l2dl_l2_cfg_seq extends nr_l2dl_init_seq;
   `uvm_object_utils(nr_l2dl_l2_cfg_seq)
   
   //function and task
   extern function new(string name="nr_l2dl_l2_cfg_seq");
   extern virtual task body();
   extern virtual task set_glb_cfg();
   extern virtual task read_glb_cfg();
   extern virtual task write_glb_cfg();

endclass: nr_l2dl_l2_cfg_seq

function nr_l2dl_l2_cfg_seq::new(string name="nr_l2dl_l2_cfg_seq");
   super.new(name);
endfunction : new

task nr_l2dl_l2_cfg_seq::body();
      `uvm_info(get_name(), "nr_l2dl_l2_cfg_seq begin...", UVM_NONE);
      get_config();
      set_model(m_l2_reg_model);
      set_glb_cfg();
      `uvm_info(get_name(), "nr_l2dl_l2_cfg_seq end...", UVM_NONE)
endtask : body

task nr_l2dl_l2_cfg_seq::set_glb_cfg();
    write_field_by_name("dbg_out_space", "globle_cfg_reg2_globle_cfg_reg3", m_nr_l2dl_env_cfg.dbg_out_space);
    write_field_by_name("dbg_out_addr", "globle_cfg_reg2_globle_cfg_reg3", m_nr_l2dl_env_cfg.dbg_out_addr);
    write_field_by_name("acc_node_space", "dma_cfg_reg0_dma_cfg_reg1", m_nr_l2dl_env_cfg.acc_node_space);
    write_field_by_name("dl_node0_space", "dma_cfg_reg0_dma_cfg_reg1", m_nr_l2dl_env_cfg.dl_node0_space);
    write_field_by_name("dl_node1_space", "dma_cfg_reg0_dma_cfg_reg1", m_nr_l2dl_env_cfg.dl_node1_space);
    write_field_by_name("tb_info2_space", "dma_cfg_reg2_dma_cfg_reg3", m_nr_l2dl_env_cfg.tb_info2_space);
    write_field_by_name("macce_node2_space", "dma_cfg_reg2_dma_cfg_reg3", m_nr_l2dl_env_cfg.macce_node2_space);
    write_field_by_name("macce_pld_space", "dma_cfg_reg2_dma_cfg_reg3", m_nr_l2dl_env_cfg.macce_pld_space);
    write_field_by_name("macce_pld_addr", "dma_cfg_reg2_dma_cfg_reg3", m_nr_l2dl_env_cfg.macce_pld_addr);
    write_field_by_name("dl_node0_dma_addr", "dma_cfg_reg4_dma_cfg_reg5", m_nr_l2dl_env_cfg.dl_node0_dma_addr);
    write_field_by_name("dl_node1_dma_addr", "dma_cfg_reg4_dma_cfg_reg5", m_nr_l2dl_env_cfg.dl_node1_dma_addr);
    write_field_by_name("acc_node_dma_addr", "dma_cfg_reg6_dma_cfg_reg7", m_nr_l2dl_env_cfg.acc_node_dma_addr);
    write_field_by_name("macce_node2_dma_addr", "dma_cfg_reg6_dma_cfg_reg7", m_nr_l2dl_env_cfg.macce_node2_dma_addr);
    write_field_by_name("tb_info2_dma_addr", "dma_cfg_reg8_dma_blkaddr_fifo_reg_0", m_nr_l2dl_env_cfg.tb_info2_dma_addr);
endtask : set_glb_cfg

task nr_l2dl_l2_cfg_seq::read_glb_cfg();
    bit [63:0] l2_tbinfo_idx; 
    read_reg_by_name("logic_ch_reg0_c0_logic_ch_reg1_c0", l2_tbinfo_idx);
    read_reg_by_name("l2_tbinfo_idx_reg", l2_tbinfo_idx);
    read_reg_by_name("dma_cfg_reg8_dma_blkaddr_fifo_reg_0", l2_tbinfo_idx);
endtask : read_glb_cfg

task nr_l2dl_l2_cfg_seq::write_glb_cfg();
    write_field_by_name("l2_tbinfo_idx_latch", "l2_tbinfo_idx_reg", 1'b1);
    write_field_by_name("l2_tbinfo_sync_st_clr", "l2_tbinfo_idx_reg", 1'b1);
    write_field_by_name("blkaddr_fifo_clr", "dma_cfg_reg8_dma_blkaddr_fifo_reg_0", 1'b1);
endtask : write_glb_cfg
//: nr_l2dl_l2_cfg_seq
 
`endif

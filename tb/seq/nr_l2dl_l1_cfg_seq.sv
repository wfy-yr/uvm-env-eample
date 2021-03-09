// =========================================================================== //
// Author       : fengyang.wu - ASR
// Last modified: 2020-07-10 11:00
// Filename     : nr_l2dl_l1_cfg_seq.sv
// Description  : 
// =========================================================================== //
`ifndef NR_L2DL_L1_CFG_SEQ__SV
`define NR_L2DL_L1_CFG_SEQ__SV

class nr_l2dl_l1_cfg_seq extends nr_l2dl_init_seq;
   `uvm_object_utils(nr_l2dl_l1_cfg_seq)
   
   //function and task
   extern function new(string name="nr_l2dl_l1_cfg_seq");
   extern virtual task body();
   extern virtual task set_l1_cfg();
   extern virtual task read_l1_cfg();
   extern virtual task write_l1_cfg();

endclass: nr_l2dl_l1_cfg_seq

function nr_l2dl_l1_cfg_seq::new(string name="nr_l2dl_l1_cfg_seq");
   super.new(name);
endfunction : new

task nr_l2dl_l1_cfg_seq::body();
      `uvm_info(get_name(), "nr_l2dl_l1_cfg_seq begin...", UVM_NONE);
      get_config();
      set_model(m_l1_reg_model);
      set_l1_cfg();
      `uvm_info(get_name(), "nr_l2dl_l1_cfg_seq end...", UVM_NONE)
endtask : body

task nr_l2dl_l1_cfg_seq::set_l1_cfg();
    write_field_by_name("tb_info1_space", "l1_dma_cfg_reg1_l1_dma_cfg_reg2", m_nr_l2dl_env_cfg.tb_info1_space);
    write_field_by_name("macce_node1_space", "l1_dma_cfg_reg1_l1_dma_cfg_reg2", m_nr_l2dl_env_cfg.macce_node1_space);
    write_field_by_name("tb_info1_dma_addr", "l1_dma_cfg_reg1_l1_dma_cfg_reg2", m_nr_l2dl_env_cfg.tb_info1_dma_addr);
    write_reg_by_name("l1_tbinfo_idx_reg_l1_dma_cfg_reg0", {m_nr_l2dl_env_cfg.macce_node1_dma_addr,32'h12345678});
endtask : set_l1_cfg

task nr_l2dl_l1_cfg_seq::read_l1_cfg();
    bit [63:0] l1_tbinfo_idx;
    read_reg_by_name("l1_tbinfo_idx_reg_l1_dma_cfg_reg0", l1_tbinfo_idx);
endtask : read_l1_cfg

task nr_l2dl_l1_cfg_seq::write_l1_cfg();
    write_field_by_name("l1_tbinfo_idx_latch", "l1_tbinfo_idx_reg_l1_dma_cfg_reg0", 1'b1);
    write_field_by_name("l1_tbinfo_sync_st_clr", "l1_tbinfo_idx_reg_l1_dma_cfg_reg0", 1'b1);
endtask : write_l1_cfg
//: nr_l2dl_l1_cfg_seq
 
`endif

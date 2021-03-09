// =========================================================================== //
// Author       : fengyang.wu - ASR
// Last modified: 2020-07-10 11:00
// Filename     : nr_l2dl_init_regbus_seq.sv
// Description  : 
// =========================================================================== //
`ifndef NR_L2DL_INIT_REGBUS_SEQ_SV
`define NR_L2DL_INIT_REGBUS_SEQ_SV

class nr_l2dl_init_regbus_seq extends regbus_reset_sequence;
    virtual nr_l2dl_top_intf      nr_l2dl_top_vif;
    `uvm_object_utils(nr_l2dl_init_regbus_seq)
   
    //function and task
    extern function new(string name="nr_l2dl_init_regbus_seq");
    extern virtual task body();
    extern virtual task reset_signal_proc();

endclass: nr_l2dl_init_regbus_seq

function nr_l2dl_init_regbus_seq::new(string name="nr_l2dl_init_regbus_seq");
   super.new(name);
endfunction : new

task nr_l2dl_init_regbus_seq::body();
      regbus_item reset_item;
      if(!uvm_config_db#(virtual nr_l2dl_top_intf)::get(m_sequencer, "", "vif", nr_l2dl_top_vif) &&
         !uvm_config_db#(virtual nr_l2dl_top_intf)::get(null, get_full_name(), "vif", nr_l2dl_top_vif)) begin
          `uvm_fatal("IP.DBG", $sformatf("[%s Can't get nr_l2dl_top_vif handle]", m_sequencer.get_full_name()))
      end      
      `uvm_info(get_name(), "nr_l2dl_init_regbus_seq begin...", UVM_NONE);
      reset_signal_proc(); 
      `uvm_do_with(reset_item,{iaddr == 'h0; iwdata == 64'h0; kind == WRITE_64; ilane == 2'h3;})
      wait(nr_l2dl_top_vif.rst == 1'b1);
      `uvm_info(get_name(), "nr_l2dl_init_regbus_seq end...", UVM_NONE)
      
endtask : body


task nr_l2dl_init_regbus_seq::reset_signal_proc();
    nr_l2dl_top_vif.mem_ctrl        <= 64'h2aaa82d474111905;
    nr_l2dl_top_vif.l2mac_rvld      <= 'h0; 
    nr_l2dl_top_vif.l2mac_rdata     <= 'h0;
    nr_l2dl_top_vif.l2_trig         <= 'h0;
    nr_l2dl_top_vif.l2_tag          <= 'h0;
endtask : reset_signal_proc



//: nr_l2dl_init_regbus_seq
 
`endif

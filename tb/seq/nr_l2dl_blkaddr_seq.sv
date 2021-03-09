// =========================================================================== //
// Author       : fengyang.wu - ASR
// Last modified: 2020-07-10 11:00
// Filename     : nr_l2dl_blkaddr_seq.sv
// Description  : 
// =========================================================================== //
`ifndef NR_L2DL_BLKADDR_SEQ_SV
`define NR_L2DL_BLKADDR_SEQ_SV

class nr_l2dl_blkaddr_seq extends nr_l2dl_base_seq;
   regbus_item  tr_q;
   `uvm_object_utils(nr_l2dl_blkaddr_seq)
   
   //function and task
   extern function new(string name="nr_l2dl_blkaddr_seq");
   extern virtual task body();

endclass: nr_l2dl_blkaddr_seq

function nr_l2dl_blkaddr_seq::new(string name="nr_l2dl_blkaddr_seq");
   super.new(name);
endfunction : new

task nr_l2dl_blkaddr_seq::body();

      `uvm_info(get_name(), "nr_l2dl_blkaddr_seq begin...", UVM_NONE);
      tr_q.set_sequencer(m_sequencer);
      `uvm_send(tr_q)
      `uvm_info(get_name(), "nr_l2dl_blkaddr_seq end...", UVM_NONE)
endtask : body
//: nr_l2dl_blkaddr_seq
 
`endif

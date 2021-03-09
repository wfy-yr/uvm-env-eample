// Author       : fengyang.wu - ASR
// Last modified: 2020-7-10 14:38
// Filename     : nr_l2dl_vseqr.sv
// Description  : 
// =========================================================================== //


class nr_l2dl_vseqr extends uvm_sequencer;

   //svt_ahb_master_transaction_sequencer    m_nr_l2dl_ahb_seqr;  
   //svt_apb_master_sequencer                m_nr_l2dl_apb_seqr;  
   //eg : nr_l2dl_src_fifo_sequencer          m_nr_l2dl_in_seqr;
   
   regbus_sequencer              m_l1_cfg_seqr;
   regbus_sequencer              m_l2_cfg_seqr;
   rx_mac_tb_cmd_sequencer       m_nr_l2dl_tb_cmd_seqr;
   regbus_sequencer              nr_l2dl_blkaddr_seqr;
   `uvm_component_utils(nr_l2dl_vseqr)

   

   function new(string name = "unnamed-nr_l2dl_vseqr", input uvm_component parent = null);
      super.new(name, parent);
   endfunction : new
endclass: nr_l2dl_vseqr



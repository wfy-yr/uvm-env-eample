// =========================================================================== //
// Author       : fengyang.wu - ASR
// Last modified: 2020-03-18 18:50
// Filename     : asr_dst_fifo_sequencer.sv
// Description  : 
// =========================================================================== //
`ifndef ASR_DST_FIFO_SEQUENCER__SV
`define ASR_DST_FIFO_SEQUENCER__SV

class asr_dst_fifo_sequencer extends uvm_sequencer #(asr_dst_fifo_trans);
    `uvm_component_utils(asr_dst_fifo_sequencer)
    function new (string name, uvm_component parent);
       super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
       super.build_phase(phase);
       `uvm_info($sformatf("%25s", get_name()), "asr_dst_fifo_sequencer begin", UVM_LOW);


       `uvm_info($sformatf("%25s", get_name()), "asr_dst_fifo_sequencer end", UVM_LOW);
    endfunction
endclass

`endif



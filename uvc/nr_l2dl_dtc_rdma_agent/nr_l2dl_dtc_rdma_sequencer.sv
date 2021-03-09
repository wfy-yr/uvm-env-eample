// =========================================================================== //
// Author       : fengyang.wu - ASR
// Last modified: 2020-03-18 18:50
// Filename     : nr_l2dl_dtc_rdma_sequencer.sv
// Description  : 
// =========================================================================== //
`ifndef NR_L2DL_DTC_RDMA_SEQUENCER__SV
`define NR_L2DL_DTC_RDMA_SEQUENCER__SV

class nr_l2dl_dtc_rdma_sequencer extends uvm_sequencer #(nr_l2dl_dtc_rdma_trans);
    `uvm_component_utils(nr_l2dl_dtc_rdma_sequencer)
    function new (string name, uvm_component parent);
       super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
       super.build_phase(phase);
       `uvm_info($sformatf("%25s", get_name()), "nr_l2dl_dtc_rdma_sequencer begin", UVM_LOW);


       `uvm_info($sformatf("%25s", get_name()), "nr_l2dl_dtc_rdma_sequencer end", UVM_LOW);
    endfunction
endclass

`endif



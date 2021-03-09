`ifndef NR_L2DL_MCE_CFG__SV 
`define NR_L2DL_MCE_CFG__SV 
class nr_l2dl_mce_cfg extends uvm_object;

    rand bit               lcid_valid;
    rand bit               fix_length;
    rand bit [5:0]         length;
    
    `uvm_object_utils_begin(nr_l2dl_mce_cfg)
        `uvm_field_int(lcid_valid, UVM_ALL_ON)
        `uvm_field_int(fix_length, UVM_ALL_ON)
        `uvm_field_int(length, UVM_ALL_ON)
    `uvm_object_utils_end                   


    function new (string name = "nr_l2dl_mce_cfg");
        super.new(name);
    endfunction : new
endclass : nr_l2dl_mce_cfg
`endif

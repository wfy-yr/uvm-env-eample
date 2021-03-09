// =========================================================================== //
// Author       : fengyang.wu - ASR
// Last modified: 2020-07-10 18:47
// Filename     : asr_src_fifo_agent_cfg.sv
// Description  : 
// =========================================================================== //
`ifndef ASR_SRC_FIFO_AGENT_CFG__SV
`define ASR_SRC_FIFO_AGENT_CFG__SV

class asr_src_fifo_agent_cfg extends uvm_object;

    uvm_active_passive_enum is_active = UVM_ACTIVE;   
    bit    checks_enable        = 1;
    bit    transformer_enable   = 1;
    bit    coverage_enable      = 1;
    bit    drv_timeout_chk      = 1;
    int    drv_timeout_ns       = 2000_0000;
    bit    drv_busy             = 0;  //for end of test objection
    bit    mon_busy             = 0;  //for end of test objection

    bit    master_mode; //1 : drv wr, 0 : drv full
    bit    special_mode_for_macbm_en;
    bit    overflow_test_en;

    int unsigned     data_width;
    int unsigned     depth;
    int unsigned     ch_id;

    // constraint for slave mode
    bit           full_val_init =1;
    int unsigned  full_interval_min=1;
    int unsigned  full_interval_max=10; // full_interval =0 : always full
    int unsigned  full_pulse_min=1;
    int unsigned  full_pulse_max=10; // full_interval =1 : always not full
    

    rand int         seq_item_cnt;
    int unsigned     single_tb_id_max;

    constraint seq_item_cnt_vld {
        seq_item_cnt inside {[1:2048]};
    }
   
   
   `uvm_object_utils_begin(asr_src_fifo_agent_cfg)
       `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_DEFAULT)
       `uvm_field_int(master_mode, UVM_DEFAULT)
       `uvm_field_int(data_width, UVM_DEFAULT)
       `uvm_field_int(depth, UVM_DEFAULT)
       `uvm_field_int(full_val_init, UVM_DEFAULT)
       `uvm_field_int(full_interval_min, UVM_DEFAULT)
       `uvm_field_int(full_interval_max, UVM_DEFAULT)
       `uvm_field_int(full_pulse_min, UVM_DEFAULT)
       `uvm_field_int(full_pulse_max, UVM_DEFAULT)
       `uvm_field_int(checks_enable, UVM_DEFAULT)
       `uvm_field_int(transformer_enable, UVM_DEFAULT)
       `uvm_field_int(coverage_enable, UVM_DEFAULT)
       `uvm_field_int(drv_timeout_chk, UVM_DEFAULT)
       `uvm_field_int(drv_timeout_ns, UVM_DEFAULT)
       `uvm_field_int(seq_item_cnt, UVM_DEFAULT)
       `uvm_field_int(drv_busy, UVM_DEFAULT)
       `uvm_field_int(mon_busy, UVM_DEFAULT)
       `uvm_field_int(special_mode_for_macbm_en, UVM_DEFAULT)
       `uvm_field_int(overflow_test_en, UVM_DEFAULT)
   `uvm_object_utils_end

   function new (string name = "asr_src_fifo_agent_cfg");
       super.new(name);
   endfunction

endclass: asr_src_fifo_agent_cfg

`endif


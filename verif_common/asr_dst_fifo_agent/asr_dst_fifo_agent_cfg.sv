// =========================================================================== //
// Author       : fengyang.wu - ASR
// Last modified: 2020-07-10 18:47
// Filename     : asr_dst_fifo_agent_cfg.sv
// Description  : 
// =========================================================================== //
`ifndef ASR_DST_FIFO_AGENT_CFG__SV
`define ASR_DST_FIFO_AGENT_CFG__SV

class asr_dst_fifo_agent_cfg extends uvm_object;

    uvm_active_passive_enum is_active = UVM_ACTIVE;   
    bit    checks_enable        = 1;
    bit    transformer_enable   = 1;
    bit    coverage_enable      = 1;
    bit    drv_timeout_chk      = 1;
    int    drv_timeout_ns       = 1000_0000;
    bit    drv_busy             = 0;  //for end of test objection
    bit    mon_busy             = 0;  //for end of test objection

    bit    master_mode; //1 : drv rd, 0 : drv empty
    bit    prefetch_mode; //0: !empty -> rd -> data
    bit    arb_mode;
    bit    timeout_en =1;

    int unsigned     data_width;
    int unsigned     depth;
    int unsigned     ch_id;

    rand int    seq_item_cnt;

    constraint seq_item_cnt_vld {
        seq_item_cnt inside {[1:100]};
    }
   
    int unsigned  req_interval_min=1;
    int unsigned  req_interval_max=10;
   
   `uvm_object_utils_begin(asr_dst_fifo_agent_cfg)
       `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_DEFAULT)
       `uvm_field_int(master_mode, UVM_DEFAULT)
       `uvm_field_int(prefetch_mode, UVM_DEFAULT)
       `uvm_field_int(arb_mode, UVM_DEFAULT)
       `uvm_field_int(data_width, UVM_DEFAULT)
       `uvm_field_int(depth, UVM_DEFAULT)
       `uvm_field_int(transformer_enable, UVM_DEFAULT)
       `uvm_field_int(coverage_enable, UVM_DEFAULT)
       `uvm_field_int(drv_timeout_chk, UVM_DEFAULT)
       `uvm_field_int(drv_timeout_ns, UVM_DEFAULT)
       `uvm_field_int(seq_item_cnt, UVM_DEFAULT)
       `uvm_field_int(drv_busy, UVM_DEFAULT)
       `uvm_field_int(mon_busy, UVM_DEFAULT)
   `uvm_object_utils_end

   function new (string name = "asr_dst_fifo_agent_cfg");
       super.new(name);
   endfunction

endclass: asr_dst_fifo_agent_cfg

`endif


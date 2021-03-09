// =========================================================================== //
// Author       : fengyang.wu - ASR
// Last modified: 2020-07-10 18:45
// Filename     : asr_src_fifo_agent.sv
// Description  : 
// =========================================================================== //
`ifndef ASR_SRC_FIFO_AGENT__SV
`define ASR_SRC_FIFO_AGENT__SV

class asr_src_fifo_agent extends uvm_agent;

    asr_src_fifo_agent_cfg        cfg;
    virtual asr_src_fifo_intf     vif;

    asr_src_fifo_sequencer        sqr;
    asr_src_fifo_driver           drv;
    asr_src_fifo_monitor          mon;

    string cov_name;
    // factory register 
    `uvm_component_utils_begin(asr_src_fifo_agent)
        `uvm_field_object(cfg, UVM_DEFAULT | UVM_REFERENCE)
    `uvm_component_utils_end
    // function and task
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    extern virtual function void build_phase(uvm_phase phase);
    extern virtual function void connect_phase(uvm_phase phase);

endclass: asr_src_fifo_agent

function void asr_src_fifo_agent::build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info($sformatf("%25s", get_name()), $sformatf("build_phase begin"), UVM_LOW)

    if(!uvm_config_db#(asr_src_fifo_agent_cfg)::get(this, "", "cfg", cfg)) begin
       `uvm_fatal(get_full_name(), $psprintf("Can not get cfg in asr_src_fifo_agent!"))
    end

    if(!uvm_config_db#(virtual asr_src_fifo_intf)::get(this, "", "vif", vif)) begin
       `uvm_fatal(get_full_name(), $psprintf("Can not get vif in asr_src_fifo_agent!"))
    end

    uvm_config_db#(asr_src_fifo_agent_cfg)::set(this, "*", "cfg", cfg);
    uvm_config_db#(virtual asr_src_fifo_intf)::set(this, "*", "vif", vif);
    
    if(cfg.is_active == UVM_ACTIVE) begin
       sqr = asr_src_fifo_sequencer::type_id::create("sqr", this);
       drv = asr_src_fifo_driver::type_id::create("drv", this);

       //for dynamic reset
       uvm_config_db#(asr_src_fifo_sequencer)::set(this, "drv", "sqr", sqr);

    end

    mon = asr_src_fifo_monitor::type_id::create("mon",this);
    mon.cov_name = this.cov_name;

    vif.is_active = cfg.is_active;
    vif.master_mode = cfg.master_mode;
    vif.cfg_toggle = ~vif.cfg_toggle;

    `uvm_info($sformatf("%25s", get_name()), $sformatf("build_phase end"), UVM_LOW)
endfunction : build_phase

function void asr_src_fifo_agent::connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if(cfg.is_active == UVM_ACTIVE) begin
       drv.seq_item_port.connect(sqr.seq_item_export);
    end

endfunction : connect_phase

`endif




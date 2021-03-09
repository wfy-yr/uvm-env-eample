// =========================================================================== //
// Author       : fengyang.wu - ASR
// Last modified: 2020-07-10 18:45
// Filename     : nr_l2dl_dtc_rdma_agent.sv
// Description  : 
// =========================================================================== //
`ifndef NR_L2DL_DTC_RDMA_AGENT__SV
`define NR_L2DL_DTC_RDMA_AGENT__SV

class nr_l2dl_dtc_rdma_agent extends uvm_agent;

    nr_l2dl_dtc_rdma_agent_cfg        cfg;
    virtual nr_l2dl_dtc_rdma_intf     vif;
    virtual nr_l2dl_top_intf          top_vif;

    nr_l2dl_dtc_rdma_sequencer        sqr;
    nr_l2dl_dtc_rdma_driver           drv;
    nr_l2dl_dtc_rdma_monitor          mon;
    nr_l2dl_dtc_rdma_scb_transformer  transformer;

    string cov_name;
    // factory register 
    `uvm_component_utils_begin(nr_l2dl_dtc_rdma_agent)
        `uvm_field_object(cfg, UVM_DEFAULT | UVM_REFERENCE)
    `uvm_component_utils_end
    // function and task
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    extern virtual function void build_phase(uvm_phase phase);
    extern virtual function void connect_phase(uvm_phase phase);

endclass: nr_l2dl_dtc_rdma_agent

function void nr_l2dl_dtc_rdma_agent::build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info($sformatf("%25s", get_name()), $sformatf("build_phase begin"), UVM_LOW)

    if(!uvm_config_db#(nr_l2dl_dtc_rdma_agent_cfg)::get(this, "", "cfg", cfg)) begin
       `uvm_fatal(get_full_name(), $psprintf("Can not get cfg in nr_l2dl_dtc_rdma_agent!"))
    end

    if(!uvm_config_db#(virtual nr_l2dl_dtc_rdma_intf)::get(this, "", "vif", vif)) begin
       `uvm_fatal(get_full_name(), $psprintf("Can not get vif in nr_l2dl_dtc_rdma_agent!"))
    end

    if(!uvm_config_db#(virtual nr_l2dl_top_intf)::get(this, "", "vif", top_vif)) begin
        `uvm_fatal(get_full_name(), $psprintf("Can not get top_vif in nr_l2dl_dtc_rdma_agent!"))
    end

    uvm_config_db#(nr_l2dl_dtc_rdma_agent_cfg)::set(this, "*", "cfg", cfg);
    uvm_config_db#(virtual nr_l2dl_dtc_rdma_intf)::set(this, "*", "vif", vif);
    uvm_config_db#(virtual nr_l2dl_top_intf)::set(this, "*", "vif", top_vif);

    $display("the value of cfg.transformer enable %d",cfg.transformer_enable);
    if(cfg.transformer_enable)begin
        transformer = nr_l2dl_dtc_rdma_scb_transformer::type_id::create("transformer", this);
    end
    
    if(cfg.is_active == UVM_ACTIVE) begin
       sqr = nr_l2dl_dtc_rdma_sequencer::type_id::create("sqr", this);
       drv = nr_l2dl_dtc_rdma_driver::type_id::create("drv", this);

       //for dynamic reset
       uvm_config_db#(nr_l2dl_dtc_rdma_sequencer)::set(this, "drv", "sqr", sqr);

    end

    mon = nr_l2dl_dtc_rdma_monitor::type_id::create("mon",this);
    mon.cov_name = this.cov_name;

    vif.is_active = cfg.is_active;
    vif.cfg_toggle = ~vif.cfg_toggle;

    `uvm_info($sformatf("%25s", get_name()), $sformatf("build_phase end"), UVM_LOW)
endfunction : build_phase

function void nr_l2dl_dtc_rdma_agent::connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if(cfg.is_active == UVM_ACTIVE) begin
       drv.seq_item_port.connect(sqr.seq_item_export);
       drv.rsp_port.connect(sqr.rsp_export);
    end
    if(cfg.transformer_enable)begin
        mon.mon_port.connect(transformer.transform_export);
    end

endfunction : connect_phase

`endif




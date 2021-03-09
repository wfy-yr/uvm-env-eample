// =========================================================================== //
// Author       : fengyang.wu - ASR
// Last modified: 2020-07-10 18:48
// Filename     : asr_dst_fifo_driver.sv
// Description  : 
// =========================================================================== //
`ifndef ASR_DST_FIFO_DRIVER_SV
`define ASR_DST_FIFO_DRIVER_SV

typedef class asr_dst_fifo_driver_cb;

class asr_dst_fifo_driver extends uvm_driver #(asr_dst_fifo_trans);

    virtual asr_dst_fifo_intf           vif;
    asr_dst_fifo_sequencer              sqr;

    asr_dst_fifo_agent_cfg              cfg;
 
    // count trans sent
    int num_sent = 0;
    `uvm_register_cb(asr_dst_fifo_driver, asr_dst_fifo_driver_cb)
    `uvm_component_utils_begin(asr_dst_fifo_driver)
        `uvm_field_int(num_sent, UVM_ALL_ON)
        `uvm_field_object(cfg, UVM_ALL_ON)
    `uvm_component_utils_end

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    extern virtual function void build_phase(uvm_phase phase);

    extern virtual task reset_vif_sigs();
    extern virtual task run_phase(uvm_phase phase);
    extern virtual task get_and_drive();
    extern virtual task req_drive(asr_dst_fifo_trans tr);
    extern virtual task mst_drive();

    //Timeout methods
    extern virtual task timeout_mon();

    //dynamic reset task
    //don't care if not need dynamic reset
    //if want to use it, please finish reset_drv_properties only
    extern virtual task dynamic_rst(uvm_phase phase);
    extern virtual task reset_all(uvm_phase phase);
    extern virtual task reset_drv_properties(uvm_phase phase);
    extern virtual function void report_phase(uvm_phase phase);
endclass: asr_dst_fifo_driver

function void asr_dst_fifo_driver::build_phase(uvm_phase phase); //{{{
    super.build_phase(phase);

    if(!uvm_config_db#(virtual asr_dst_fifo_intf)::get(this, "", "vif", vif)) begin
       `uvm_fatal(get_full_name(), $psprintf("Can not get vif !"))
    end

    if(!uvm_config_db#(asr_dst_fifo_agent_cfg)::get(this, "", "cfg", cfg)) begin
       `uvm_fatal(get_full_name(), $psprintf("Can not get cfg !"))
    end
    if(!uvm_config_db#(asr_dst_fifo_sequencer)::get(this, "", "sqr", sqr)) begin
       `uvm_fatal(get_full_name(), $psprintf("Can not get sqr !"))
    end
endfunction : build_phase //}}}

task asr_dst_fifo_driver::reset_vif_sigs(); //{{{
    `uvm_info($sformatf("%25s", get_full_name()), $sformatf("Reset asr_dst_fifo signal"), UVM_MEDIUM)
    if(cfg.master_mode)begin
        vif.mst_drvcb.req <= 'b0;
    end
    else begin
        vif.slv_drvcb.empty <= 'b1;
        vif.slv_drvcb.rdata <= {`ASR_DST_FIFO_MAX_DATA_WIDTH{1'b0}};
    end
endtask : reset_vif_sigs //}}}

task asr_dst_fifo_driver::run_phase(uvm_phase phase); //{{{
    //reset dut
    reset_vif_sigs();
    if(cfg.drv_timeout_chk) timeout_mon();
    fork 
        forever begin
            fork
                get_and_drive();
            join_none
            dynamic_rst(phase);
            disable fork;
        end
    join
    `uvm_info($sformatf("%25s", get_full_name()), $sformatf("run_phase end"), UVM_LOW)
endtask : run_phase //}}}

task asr_dst_fifo_driver::get_and_drive(); //{{{
    if(cfg.master_mode)begin
        mst_drive();
    end
    else begin
        forever begin
            seq_item_port.get_next_item(req);
            cfg.drv_busy = 1;
            `uvm_do_callbacks(asr_dst_fifo_driver, asr_dst_fifo_driver_cb, pre_get_and_drive(req));
            req_drive(req);
            `uvm_do_callbacks(asr_dst_fifo_driver, asr_dst_fifo_driver_cb, pos_get_and_drive(req));
            seq_item_port.item_done();
            cfg.drv_busy = 0;
        end
    end
endtask : get_and_drive //}}}

task asr_dst_fifo_driver::req_drive(asr_dst_fifo_trans tr); //{{{
    bit bit_stream[];

    num_sent++;
    
    `uvm_info($sformatf("%25s", get_full_name()), $sformatf("Item %0d Sent ...", num_sent), UVM_MEDIUM)

    //TODO: Finish Bus protocol according to Spec

    if(cfg.prefetch_mode)begin
        vif.slv_drvcb.empty <= 0;
        void'(tr.pack(bit_stream, default_packer));
        foreach(bit_stream[ii]) begin
            vif.slv_drvcb.rdata[ii] <= bit_stream[ii];
        end
        @(vif.slv_drvcb iff vif.slv_drvcb.req);
        vif.slv_drvcb.empty <= 1;
    end
    else begin
        vif.slv_drvcb.empty <= 0;
        void'(tr.pack(bit_stream, default_packer));
        foreach(bit_stream[ii]) begin
            vif.slv_drvcb.rdata[ii] <= bit_stream[ii];
        end
        @(vif.slv_drvcb iff vif.slv_drvcb.req);
        vif.slv_drvcb.empty <= 1;
    end
    repeat(tr.delay) begin
        @(vif.slv_drvcb);
    end
endtask : req_drive // }}}

task asr_dst_fifo_driver::mst_drive(); //{{{
    int unsigned interval;

    @(vif.mst_drvcb);

    forever begin
        if(vif.mst_drvcb.empty === 1) begin
            @(vif.mst_drvcb iff vif.mst_drvcb.empty === 0);
        end

        assert(std::randomize(interval) with {
            interval >= cfg.req_interval_min;
            interval <= cfg.req_interval_max;
        });

        `uvm_do_callbacks(asr_dst_fifo_driver, asr_dst_fifo_driver_cb, post_calc_interval(interval));

        repeat(interval) begin
            @(vif.mst_drvcb);
        end

        vif.mst_drvcb.req <= 'b1;
        @(vif.mst_drvcb);
        vif.mst_drvcb.req <= 'b0;
        @(vif.mst_drvcb);

    end
endtask : mst_drive //}}}

task asr_dst_fifo_driver::timeout_mon(); //{{{
    fork
        forever begin
            wait(cfg.drv_busy == 1);
            fork
                begin
                    #(cfg.drv_timeout_ns*1ns);
                    if(cfg.timeout_en)
                        `uvm_fatal(get_full_name(), $sformatf("trans sending started before, but no further actions for %0d ns", cfg.drv_timeout_ns))
                end
                wait(cfg.drv_busy == 0);
            join_any
            disable fork;
        end
    join_none
endtask : timeout_mon //}}}

task asr_dst_fifo_driver::dynamic_rst(uvm_phase phase); //{{{
    wait(vif.rst);
    wait(!vif.rst);
    //reset interface and properties in driver
    reset_all(phase);
endtask : dynamic_rst //}}}

task asr_dst_fifo_driver::reset_all(uvm_phase phase); //{{{
    reset_drv_properties(phase);
    reset_vif_sigs();
endtask : reset_all //}}}

task asr_dst_fifo_driver::reset_drv_properties(uvm_phase phase); //{{{
    asr_dst_fifo_trans trans;
    //----------seq item port reset
    while (sqr.m_req_fifo.used()) begin
        seq_item_port.item_done();
    end
    //----------driver property
endtask : reset_drv_properties //}}}

function void asr_dst_fifo_driver::report_phase(uvm_phase phase); //{{{
    `uvm_info($sformatf("%25s", get_full_name()), $sformatf("\nReport: asr_dst_fifo_rx driver sent %0d transfers", num_sent), UVM_LOW)
endfunction : report_phase //}}}

class asr_dst_fifo_driver_cb extends uvm_callback;
    `uvm_object_utils(asr_dst_fifo_driver_cb)
    function new(string name = "asr_dst_fifo_driver_cb");
        super.new(name);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction : new

    virtual function void pre_get_and_drive(asr_dst_fifo_trans tr);
        `uvm_info(get_full_name, {$sformatf("Callback : pre_get_and_drive"), "\n", tr.sprint}, UVM_HIGH);
    endfunction

    virtual function void pos_get_and_drive(asr_dst_fifo_trans tr);
        `uvm_info(get_full_name, {$sformatf("Callback : pos_get_and_drive"), "\n", tr.sprint}, UVM_HIGH);
    endfunction

    virtual function void post_calc_interval(ref int unsigned interval);
        `uvm_info(get_full_name(), $sformatf("Callback : post_calc_interval"), UVM_HIGH);
    endfunction
endclass : asr_dst_fifo_driver_cb

`endif





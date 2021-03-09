// =========================================================================== //
// Author       : fengyang.wu - ASR
// Last modified: 2020-07-10 18:48
// Filename     : asr_src_fifo_driver.sv
// Description  : 
// =========================================================================== //
`ifndef ASR_SRC_FIFO_DRIVER_SV
`define ASR_SRC_FIFO_DRIVER_SV

typedef class asr_src_fifo_driver_cb;

class asr_src_fifo_driver extends uvm_driver #(asr_src_fifo_trans);

    virtual asr_src_fifo_intf           vif;
    asr_src_fifo_sequencer              sqr;

    asr_src_fifo_agent_cfg              cfg;
 
    // count trans sent
    int num_sent = 0;
    `uvm_register_cb(asr_src_fifo_driver, asr_src_fifo_driver_cb)
    `uvm_component_utils_begin(asr_src_fifo_driver)
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
    extern virtual task req_drive(asr_src_fifo_trans tr);
    extern virtual task full_drive();

    //Timeout methods
    extern virtual task timeout_mon();

    //dynamic reset task
    //don't care if not need dynamic reset
    //if want to use it, please finish reset_drv_properties only
    extern virtual task dynamic_rst(uvm_phase phase);
    extern virtual task reset_all(uvm_phase phase);
    extern virtual task reset_drv_properties(uvm_phase phase);
    extern virtual function void report_phase(uvm_phase phase);
endclass: asr_src_fifo_driver

function void asr_src_fifo_driver::build_phase(uvm_phase phase); //{{{
    super.build_phase(phase);

    if(!uvm_config_db#(virtual asr_src_fifo_intf)::get(this, "", "vif", vif)) begin
       `uvm_fatal(get_full_name(), $psprintf("Can not get vif !"))
    end

    if(!uvm_config_db#(asr_src_fifo_agent_cfg)::get(this, "", "cfg", cfg)) begin
       `uvm_fatal(get_full_name(), $psprintf("Can not get cfg !"))
    end
    if(!uvm_config_db#(asr_src_fifo_sequencer)::get(this, "", "sqr", sqr)) begin
       `uvm_fatal(get_full_name(), $psprintf("Can not get sqr !"))
    end
endfunction : build_phase //}}}

task asr_src_fifo_driver::reset_vif_sigs(); //{{{
    `uvm_info($sformatf("%25s", get_full_name()), $sformatf("Reset asr_src_fifo signal"), UVM_MEDIUM)
    if(cfg.master_mode)begin
        vif.mst_drvcb.valid <= 'b0;
        vif.mst_drvcb.node <= {`ASR_SRC_FIFO_MAX_DATA_WIDTH{1'b0}};
    end
    else begin
        vif.slv_drvcb.full <= 'b1;
    end
endtask : reset_vif_sigs //}}}

task asr_src_fifo_driver::run_phase(uvm_phase phase); //{{{
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

task asr_src_fifo_driver::get_and_drive(); //{{{
    if(cfg.master_mode)begin
        forever begin
            seq_item_port.get_next_item(req);
            cfg.drv_busy = 1;
            `uvm_do_callbacks(asr_src_fifo_driver, asr_src_fifo_driver_cb, pre_get_and_drive(req));
            req_drive(req);
            `uvm_do_callbacks(asr_src_fifo_driver, asr_src_fifo_driver_cb, pos_get_and_drive(req));
            seq_item_port.item_done();
            cfg.drv_busy = 0;
        end
    end
    else begin
        full_drive();
    end
endtask : get_and_drive //}}}

task asr_src_fifo_driver::req_drive(asr_src_fifo_trans tr); //{{{
    bit bit_stream[];

    num_sent++;
    
    `uvm_info($sformatf("%25s", get_full_name()), $sformatf("Item %0d Sent ...", num_sent), UVM_MEDIUM)

    //TODO: Finish Bus protocol according to Spec

    if(!cfg.special_mode_for_macbm_en)begin
        @(vif.mst_drvcb iff !vif.mst_drvcb.full);
        vif.mst_drvcb.valid <= 1'b1;
        void'(tr.pack(bit_stream, default_packer));
        foreach(bit_stream[ii]) begin
            vif.mst_drvcb.node[ii] <= bit_stream[ii];
        end
        repeat(tr.delay) begin
            @(vif.mst_drvcb);
            vif.mst_drvcb.valid <= 1'b0;
        end
    end
    else begin
        repeat(tr.delay) begin
            @(vif.mst_drvcb);
        end
        @(vif.mst_drvcb iff !vif.mst_drvcb.full);
        vif.mst_drvcb.valid <= 1'b1;
        void'(tr.pack(bit_stream, default_packer));
        foreach(bit_stream[ii]) begin
            vif.mst_drvcb.node[ii] <= bit_stream[ii];
        end
        @(vif.mst_drvcb);
        vif.mst_drvcb.valid <= 1'b0;
    end
endtask : req_drive // }}}

task asr_src_fifo_driver::full_drive(); //{{{
    bit full_val;
    int unsigned interval;
    int unsigned cycle_num;

    full_val = cfg.full_val_init;

    forever begin
        if(!cfg.overflow_test_en) begin
            full_val = ~full_val;

            if(full_val == 0) begin
                assert(std::randomize(interval) with {
                    interval >= cfg.full_interval_min;
                    interval <= cfg.full_interval_max;
                });
            end
            else begin
                assert(std::randomize(interval) with {
                    interval >= cfg.full_pulse_min;
                    interval <= cfg.full_pulse_max;
                });
            end

            `uvm_do_callbacks(asr_src_fifo_driver, asr_src_fifo_driver_cb, post_calc_interval(interval));

            if(interval == 0) begin
                vif.slv_drvcb.full <= ~full_val;
                return;
            end
            else begin
                vif.slv_drvcb.full <= ~full_val;
                repeat(interval) begin
                    @(vif.slv_drvcb);
                end
            end
        end
        else begin
            vif.slv_drvcb.full <= 'b0;
            cycle_num=$urandom_range(1,10);
            repeat(interval) begin
                @(vif.slv_drvcb iff !(vif.slv_drvcb.valid));
                @(vif.slv_drvcb iff vif.slv_drvcb.valid);
            end
            vif.slv_drvcb.full <= 'b1;
            interval = $urandom_range(1,500);
            repeat(interval) begin
                @(vif.slv_drvcb);
            end
        end
    end
endtask : full_drive //}}}

task asr_src_fifo_driver::timeout_mon(); //{{{
    fork
        forever begin
            wait(cfg.drv_busy == 1);
            fork
                begin
                    #(cfg.drv_timeout_ns*1ns);
                    `uvm_fatal(get_full_name(), $sformatf("trans sending started before, but no further actions for %0d ns", cfg.drv_timeout_ns))
                end
                wait(cfg.drv_busy == 0);
            join_any
            disable fork;
        end
    join_none
endtask : timeout_mon //}}}

task asr_src_fifo_driver::dynamic_rst(uvm_phase phase); //{{{
    wait(vif.rst);
    wait(!vif.rst);
    //reset interface and properties in driver
    reset_all(phase);
endtask : dynamic_rst //}}}

task asr_src_fifo_driver::reset_all(uvm_phase phase); //{{{
    reset_drv_properties(phase);
    reset_vif_sigs();
endtask : reset_all //}}}

task asr_src_fifo_driver::reset_drv_properties(uvm_phase phase); //{{{
    asr_src_fifo_trans trans;
    //----------seq item port reset
    while (sqr.m_req_fifo.used()) begin
        seq_item_port.item_done();
    end
    //----------driver property
endtask : reset_drv_properties //}}}

function void asr_src_fifo_driver::report_phase(uvm_phase phase); //{{{
    `uvm_info($sformatf("%25s", get_full_name()), $sformatf("\nReport: asr_src_fifo_rx driver sent %0d transfers", num_sent), UVM_LOW)
endfunction : report_phase //}}}

class asr_src_fifo_driver_cb extends uvm_callback;
    `uvm_object_utils(asr_src_fifo_driver_cb)
    function new(string name = "asr_src_fifo_driver_cb");
        super.new(name);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction : new

    virtual function void pre_get_and_drive(asr_src_fifo_trans tr);
        `uvm_info(get_full_name(), $sformatf("Callback : pre_get_and_drive \n%s", tr.sprint()), UVM_HIGH);
    endfunction

    virtual function void pos_get_and_drive(asr_src_fifo_trans tr);
        `uvm_info(get_full_name, {$sformatf("Callback : pos_get_and_drive"), "\n", tr.sprint}, UVM_HIGH);
    endfunction

    virtual function void post_calc_interval(ref int unsigned interval);
        `uvm_info(get_full_name, $sformatf("Callback : post_calc_interval"), UVM_HIGH);
    endfunction
endclass : asr_src_fifo_driver_cb

`endif





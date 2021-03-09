// =========================================================================== //
// Author       : fengyang.wu - ASR
// Last modified: 2020-07-10 18:48
// Filename     : nr_l2dl_dtc_rdma_driver.sv
// Description  : 
// =========================================================================== //
`ifndef NR_L2DL_DTC_RDMA_DRIVER_SV
`define NR_L2DL_DTC_RDMA_DRIVER_SV

typedef class nr_l2dl_dtc_rdma_driver_cb;

class nr_l2dl_dtc_rdma_driver extends uvm_driver #(nr_l2dl_dtc_rdma_trans);

    virtual nr_l2dl_dtc_rdma_intf           vif;
    nr_l2dl_dtc_rdma_sequencer              sqr;

    nr_l2dl_dtc_rdma_agent_cfg              cfg;
 
    // count trans sent
    int num_sent = 0;
    `uvm_register_cb(nr_l2dl_dtc_rdma_driver, nr_l2dl_dtc_rdma_driver_cb)
    `uvm_component_utils_begin(nr_l2dl_dtc_rdma_driver)
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
    extern virtual task req_drive(nr_l2dl_dtc_rdma_trans tr);

    //Timeout methods
    extern virtual task timeout_mon();

    //dynamic reset task
    //don't care if not need dynamic reset
    //if want to use it, please finish reset_drv_properties only
    extern virtual task dynamic_rst(uvm_phase phase);
    extern virtual task reset_all(uvm_phase phase);
    extern virtual task reset_drv_properties(uvm_phase phase);
    extern virtual function void report_phase(uvm_phase phase);
endclass: nr_l2dl_dtc_rdma_driver

function void nr_l2dl_dtc_rdma_driver::build_phase(uvm_phase phase); //{{{
    super.build_phase(phase);

    if(!uvm_config_db#(virtual nr_l2dl_dtc_rdma_intf)::get(this, "", "vif", vif)) begin
       `uvm_fatal(get_full_name(), $psprintf("Can not get vif !"))
    end

    if(!uvm_config_db#(nr_l2dl_dtc_rdma_agent_cfg)::get(this, "", "cfg", cfg)) begin
       `uvm_fatal(get_full_name(), $psprintf("Can not get cfg !"))
    end
    if(!uvm_config_db#(nr_l2dl_dtc_rdma_sequencer)::get(this, "", "sqr", sqr)) begin
       `uvm_fatal(get_full_name(), $psprintf("Can not get sqr !"))
    end
endfunction : build_phase //}}}

task nr_l2dl_dtc_rdma_driver::reset_vif_sigs(); //{{{
    `uvm_info($sformatf("%25s", get_full_name()), $sformatf("Reset nr_l2dl_dtc_rdma signal"), UVM_MEDIUM)
    //vif.drvcb.valid <= 'b0;
    //vif.drvcb.data <= {`NR_L2DL_DTC_dma_MAX_DATA_WIDTH{1'b0}};
    wait(vif.rst);
endtask : reset_vif_sigs //}}}

task nr_l2dl_dtc_rdma_driver::run_phase(uvm_phase phase); //{{{
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

task nr_l2dl_dtc_rdma_driver::get_and_drive(); //{{{
    forever begin
        seq_item_port.get_next_item(req);
        cfg.drv_busy = 1;
        `uvm_do_callbacks(nr_l2dl_dtc_rdma_driver, nr_l2dl_dtc_rdma_driver_cb, pre_get_and_drive(req));
        req_drive(req);
        `uvm_do_callbacks(nr_l2dl_dtc_rdma_driver, nr_l2dl_dtc_rdma_driver_cb, pos_get_and_drive(req));
        seq_item_port.item_done();
        cfg.drv_busy = 0;
    end
endtask : get_and_drive //}}}

task nr_l2dl_dtc_rdma_driver::req_drive(nr_l2dl_dtc_rdma_trans tr); //{{{
    bit bit_stream[];

    num_sent++;
    
    `uvm_info($sformatf("%25s", get_full_name()), $sformatf("Item %0d Sent ...", num_sent), UVM_MEDIUM)

    //TODO: Finish Bus protocol according to Spec

    //vif.drvcb.valid <= 'b0;
    //void'(tr.pack(bit_stream, default_packer));
    //foreach(bit_stream[ii]) begin
    //    vif.drvcb.data[ii] <= bit_stream[ii];
    //end
    //vif.drvcb.valid <= 'b1;
    //@(vif.drvcb);
    //vif.drvcb.valid <= 'b0;
    //repeat(tr.delay) begin
    //    @(vif.drvcb);
    //end
    `uvm_info($sformatf("%25s", get_full_name()), $sformatf("Item %0d Sent end", num_sent), UVM_HIGH)
endtask : req_drive // }}}

task nr_l2dl_dtc_rdma_driver::timeout_mon(); //{{{
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

task nr_l2dl_dtc_rdma_driver::dynamic_rst(uvm_phase phase); //{{{
    wait(vif.rst);
    wait(!vif.rst);
    //reset interface and properties in driver
    reset_all(phase);
endtask : dynamic_rst //}}}

task nr_l2dl_dtc_rdma_driver::reset_all(uvm_phase phase); //{{{
    reset_drv_properties(phase);
    reset_vif_sigs();
endtask : reset_all //}}}

task nr_l2dl_dtc_rdma_driver::reset_drv_properties(uvm_phase phase); //{{{
    nr_l2dl_dtc_rdma_trans trans;
    //----------seq item port reset
    while (sqr.m_req_fifo.used()) begin
        seq_item_port.item_done();
    end
    //----------driver property
endtask : reset_drv_properties //}}}

function void nr_l2dl_dtc_rdma_driver::report_phase(uvm_phase phase); //{{{
    `uvm_info($sformatf("%25s", get_full_name()), $sformatf("\nReport: nr_l2dl_dtc_rdma_rx driver sent %0d transfers", num_sent), UVM_LOW)
endfunction : report_phase //}}}

class nr_l2dl_dtc_rdma_driver_cb extends uvm_callback;
    `uvm_object_utils(nr_l2dl_dtc_rdma_driver_cb)
    function new(string name = "nr_l2dl_dtc_rdma_driver_cb");
        super.new(name);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction : new

    virtual function void pre_get_and_drive(nr_l2dl_dtc_rdma_trans tr);
        `uvm_info(get_full_name, {$sformatf("Callback : pre_get_and_drive"), "\n", tr.sprint}, UVM_HIGH);
    endfunction

    virtual function void pos_get_and_drive(nr_l2dl_dtc_rdma_trans tr);
        `uvm_info(get_full_name, {$sformatf("Callback : pos_get_and_drive"), "\n", tr.sprint}, UVM_HIGH);
    endfunction

    virtual function void post_calc_interval(ref int unsigned interval);
        `uvm_info(get_full_name(), $sformatf("Callback : post_calc_interval"), UVM_HIGH);
    endfunction
endclass : nr_l2dl_dtc_rdma_driver_cb

`endif





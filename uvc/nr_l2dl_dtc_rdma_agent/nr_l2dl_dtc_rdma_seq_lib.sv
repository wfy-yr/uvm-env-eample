class nr_l2dl_dtc_rdma_seq_base extends uvm_sequence #(nr_l2dl_dtc_rdma_trans);
    virtual nr_l2dl_dtc_rdma_intf    vif;
    nr_l2dl_dtc_rdma_agent_cfg       cfg; 

    //`uvm_declare_p_sequencer(nr_l2dl_dtc_rdma_sequencer)
    `uvm_object_utils(nr_l2dl_dtc_rdma_seq_base)


    extern function new(string name="nr_l2dl_dtc_rdma_seq_base");
    extern virtual task get_config();
    extern virtual task pre_start();
    extern virtual task post_start();

endclass: nr_l2dl_dtc_rdma_seq_base

function nr_l2dl_dtc_rdma_seq_base::new(string name="nr_l2dl_dtc_rdma_seq_base");
   super.new(name);
endfunction : new

task nr_l2dl_dtc_rdma_seq_base::get_config();

    if(!uvm_config_db#(nr_l2dl_dtc_rdma_agent_cfg)::get(m_sequencer, "", "cfg", cfg)) begin
        `uvm_fatal(get_full_name(), $sformatf("[RX_MAC][Can't get m_nr_l2dl_dtc_rdma_agent_cfg handle]"))
    end      


    if(!uvm_config_db#(virtual nr_l2dl_dtc_rdma_intf)::get(m_sequencer, "", "vif", vif)) begin
        `uvm_fatal(get_full_name(), $sformatf("[RX_MAC][Can't get m_nr_l2dl_dtc_rdma_intf handle]"))
    end      

endtask : get_config

task nr_l2dl_dtc_rdma_seq_base::pre_start();
   `uvm_info($sformatf("%25s", get_full_name()), $sformatf("pre_start begin"), UVM_MEDIUM)
    if(starting_phase != null) begin
        starting_phase.raise_objection(this);
    end
    get_config();
   `uvm_info($sformatf("%25s", get_full_name()), $sformatf("pre_start end"), UVM_MEDIUM)
endtask : pre_start

task nr_l2dl_dtc_rdma_seq_base::post_start();
   `uvm_info($sformatf("%25s", get_full_name()), $sformatf("post_start begin"), UVM_MEDIUM)
    if(starting_phase != null) begin
        starting_phase.drop_objection(this);
    end
   `uvm_info($sformatf("%25s", get_full_name()), $sformatf("post_start end"), UVM_MEDIUM)
endtask : post_start

class nr_l2dl_dtc_rdma_trans_seq extends nr_l2dl_dtc_rdma_seq_base;
    nr_l2dl_dtc_rdma_trans  tr_q[$];
    int num_seq_lib;
    `uvm_object_utils(nr_l2dl_dtc_rdma_trans_seq)

    function new(string name="nr_l2dl_dtc_rdma_trans_seq");
       super.new(name);
    endfunction

    virtual task body();
        `uvm_info(get_full_name(), $sformatf("[RX_MAC][Starting nr_l2dl_dtc_rdma_trans_seq body]"), UVM_LOW)

        foreach(tr_q[ii]) begin
            num_seq_lib++;
            tr_q[ii].set_sequencer(m_sequencer);
            `uvm_send(tr_q[ii])
        end
    endtask
endclass : nr_l2dl_dtc_rdma_trans_seq

class nr_l2dl_dtc_rdma_trans_seq_only1 extends nr_l2dl_dtc_rdma_seq_base;
    nr_l2dl_dtc_rdma_trans  tr_q[$];
    int unsigned trans_cnt;
    `uvm_object_utils(nr_l2dl_dtc_rdma_trans_seq_only1)

    function new(string name="nr_l2dl_dtc_rdma_trans_seq_only1");
       super.new(name);
    endfunction

    virtual task body();
        `uvm_info(get_full_name(), $sformatf("[RX_MAC][Starting nr_l2dl_dtc_rdma_trans_seq_only1 body]"), UVM_LOW)
        //tr_q[trans_cnt].set_sequencer(m_sequencer);
        //`uvm_send(tr_q[trans_cnt])
        `uvm_do(tr_q[trans_cnt])
        trans_cnt++;
        `uvm_info(get_full_name(), $sformatf("[RX_MAC][nr_l2dl_dtc_rdma_trans_seq_only1 body end]"), UVM_MEDIUM)
    endtask
endclass : nr_l2dl_dtc_rdma_trans_seq_only1

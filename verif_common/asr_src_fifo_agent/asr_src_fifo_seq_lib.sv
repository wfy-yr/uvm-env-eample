class asr_src_fifo_seq_base extends uvm_sequence #(asr_src_fifo_trans);
    virtual asr_src_fifo_intf    vif;
    asr_src_fifo_agent_cfg       cfg; 

    `uvm_declare_p_sequencer(asr_src_fifo_sequencer)
    `uvm_object_utils(asr_src_fifo_seq_base)


    extern function new(string name="asr_src_fifo_seq_base");
    extern virtual task get_config();
    extern virtual task pre_body();
    extern virtual task post_body();

endclass: asr_src_fifo_seq_base

function asr_src_fifo_seq_base::new(string name="asr_src_fifo_seq_base");
   super.new(name);
endfunction : new

task asr_src_fifo_seq_base::get_config();

    if(!uvm_config_db#(asr_src_fifo_agent_cfg)::get(m_sequencer, "", "cfg", cfg)) begin
        `uvm_fatal(get_full_name(), $sformatf("[RX_MAC][Can't get m_asr_src_fifo_agent_cfg handle]"))
    end      


    if(!uvm_config_db#(virtual asr_src_fifo_intf)::get(m_sequencer, "", "vif", vif)) begin
        `uvm_fatal(get_full_name(), $sformatf("[RX_MAC][Can't get m_asr_src_fifo_intf handle]"))
    end      

endtask : get_config

task asr_src_fifo_seq_base::pre_body();
    if(starting_phase != null) begin
        starting_phase.raise_objection(this);
    end
    get_config();
endtask : pre_body

task asr_src_fifo_seq_base::post_body();
    if(starting_phase != null) begin
        starting_phase.drop_objection(this);
    end
endtask : post_body

class asr_src_fifo_trans_seq extends asr_src_fifo_seq_base;
    asr_src_fifo_trans  tr_q[$];
    int num_seq_lib;
    `uvm_object_utils(asr_src_fifo_trans_seq)

    function new(string name="asr_src_fifo_trans_seq");
       super.new(name);
    endfunction

    virtual task body();
        `uvm_info(get_full_name(), $sformatf("[RX_MAC][Starting asr_src_fifo_trans_seq body]"), UVM_LOW)

        foreach(tr_q[ii]) begin
            num_seq_lib++;
            tr_q[ii].set_sequencer(m_sequencer);
            `uvm_send(tr_q[ii])
        end
    endtask
endclass: asr_src_fifo_trans_seq

class asr_src_fifo_trans_seq_only1 extends asr_src_fifo_seq_base;
    asr_src_fifo_trans  tr_q[$];
    int unsigned trans_cnt;
    `uvm_object_utils(asr_src_fifo_trans_seq_only1)

    function new(string name="asr_src_fifo_trans_seq_only1");
       super.new(name);
    endfunction

    virtual task body();
        `uvm_info(get_full_name(), $sformatf("[RX_MAC][Starting asr_src_fifo_trans_seq_only1 body]"), UVM_LOW)
        tr_q[trans_cnt].set_sequencer(m_sequencer);
        `uvm_send(tr_q[trans_cnt])
        trans_cnt++;
    endtask
endclass: asr_src_fifo_trans_seq_only1

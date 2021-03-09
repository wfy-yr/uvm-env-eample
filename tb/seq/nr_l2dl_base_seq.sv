// =========================================================================== //
// Author       : fengyang.wu - ASR
// Last modified: 2020-07-10 14:19
// Filename     : nr_l2dl_base_seq.sv
// Description  : 
// =========================================================================== //
// variables need to be configured in base_test or top vseq :
// 1.reg model
// 2.address map name , default = "default" --- means default map of root reg blk
// 3.blk_hier string , default =  ""

// configure method 1: via m_sequencer : only applied to top ral vseq for current env, for sub ral vseq, pls use method 2 in the top ral vseq
// uvm_config_db#(uvm_reg_block)::set(vseqr, "", "reg_model", reg_model);
// uvm_config_db#(string)::set(vseqr, "", "root_map_name", "default_map_name");
// uvm_config_db#(string)::set(vseqr, "", "blk_hier", "blk_hier");

//configure method 2: via task call
//to reuse uart ip cfg seq in ap subsystem:
//nr_l2dl_cfg_seq.set_model(.reg_model(ap_reg_model), .hier("uart_rf"), .map_name("ap")); or
//nr_l2dl_cfg_seq.set_model(.reg_model(ap_reg_model.uart_rf), .hier(""), .map_name("ap"));

//eg: (ap subsys test):
//in ap_test.sv:
//              uvm_config_db#(uvm_reg_block)::set(vseqr, "", "reg_model", ap_model);
//              uvm_config_db#(string)::set(vseqr, "", "root_map_name", ap_model);
//              uvm_config_db#(string)::set(vseqr, "", "blk_hier", blk_hier);
//          
//in ap_cfg_vseq (top ral vseq, will get ap_model as reg_model):
//              dma_cfg_seq.set_model(.reg_model(this.reg_model), .hier("dma_blk"), .map_name("ap_map"));
//              dma_cfg_seq.start(m_sequencer);
//
//in reused dma cfg seq
//             write_reg_by_name("CHN_SEL", 'hff)     // with default map "ap_map"
//             write_reg_by_name("CHN_SEL", 'hff, , "aon_map")     // with map "aon_map"
//             write_reg_by_offset('h10, 'hff, , "aon_map")     // with offset inside map "aon_map"

`ifndef NR_L2DL_BASE_SEQ_SV
`define NR_L2DL_BASE_SEQ_SV

class nr_l2dl_base_seq extends asr_ral_base_seq;
    virtual nr_l2dl_top_intf      nr_l2dl_top_vif;
    nr_l2dl_env_cfg               m_nr_l2dl_env_cfg; 
    nr_l2dl_coverage              m_nr_l2dl_coverage;
    rx_mac_reg_cfg                m_rx_mac_reg_cfg;

    uvm_reg_block                m_l1_reg_model;
    uvm_reg_block                m_l2_reg_model;

    uvm_reg_data_t               reg_data_aa[string];

    //!!!! don't define p_sequencer, otherwise cannot reuse
    `uvm_object_utils(nr_l2dl_base_seq)


    extern function new(string name="nr_l2dl_base_seq");
    extern virtual task get_config();
    extern virtual task rand_dly(int max_dly_cyc=0);
    extern virtual task reg_rand_cfg(int max_dly_cyc=0);

endclass: nr_l2dl_base_seq

function nr_l2dl_base_seq::new(string name="nr_l2dl_base_seq");
   super.new(name);
endfunction : new

task nr_l2dl_base_seq::get_config();
    //allow
    //1.directly assign
    //2.config_db by sequencer
    //3.config_db by sequence_name (to support multiple IP instances of same IP type in one subsys)

    if(m_nr_l2dl_env_cfg == null) begin
        if(!uvm_config_db#(nr_l2dl_env_cfg)::get(m_sequencer, "", "m_nr_l2dl_env_cfg", m_nr_l2dl_env_cfg) &&
           !uvm_config_db#(nr_l2dl_env_cfg)::get(null, get_full_name(), "m_nr_l2dl_env_cfg", m_nr_l2dl_env_cfg)) begin
            `uvm_fatal("IP.DBG", $sformatf("[%s Can't get m_nr_l2dl_env_cfg handle]", m_sequencer.get_full_name()))
        end      
    end

    if(m_nr_l2dl_coverage == null) begin
        if(!uvm_config_db#(nr_l2dl_coverage)::get(m_sequencer, "", "m_nr_l2dl_coverage", m_nr_l2dl_coverage) &&
           !uvm_config_db#(nr_l2dl_coverage)::get(null, get_full_name(), "m_nr_l2dl_coverage", m_nr_l2dl_coverage)) begin
            `uvm_fatal("IP.DBG", $sformatf("[%s Can't get m_nr_l2dl_coverage handle]", m_sequencer.get_full_name()))
        end      
    end

    if(!uvm_config_db#(virtual nr_l2dl_top_intf)::get(m_sequencer, "", "vif", nr_l2dl_top_vif) &&
       !uvm_config_db#(virtual nr_l2dl_top_intf)::get(null, get_full_name(), "vif", nr_l2dl_top_vif)) begin
        `uvm_fatal("IP.DBG", $sformatf("[%s Can't get nr_l2dl_top_vif handle]", m_sequencer.get_full_name()))
    end      

    if(!uvm_config_db#(uvm_reg_block)::get(m_sequencer, "", "l1_reg_model", m_l1_reg_model) &&
       !uvm_config_db#(uvm_reg_block)::get(null, get_full_name(), "l1_reg_model", m_l1_reg_model)) begin
        `uvm_fatal("IP.DBG", $sformatf("[%s Can't get reg_model handle]", m_sequencer.get_full_name()))
    end      
    if(!uvm_config_db#(uvm_reg_block)::get(m_sequencer, "", "l2_reg_model", m_l2_reg_model) &&
       !uvm_config_db#(uvm_reg_block)::get(null, get_full_name(), "l2_reg_model", m_l2_reg_model)) begin
        `uvm_fatal("IP.DBG", $sformatf("[%s Can't get reg_model handle]", m_sequencer.get_full_name()))
    end      

    m_rx_mac_reg_cfg = m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg;
endtask : get_config

task nr_l2dl_base_seq::rand_dly(int max_dly_cyc=0);
    int dly_cyc;
    if(max_dly_cyc) begin
        if(std::randomize() with {dly_cyc dist {0:=5, [0:max_dly_cyc]:/3, max_dly_cyc:=2};}) begin
            repeat(dly_cyc) @(nr_l2dl_top_vif.moncb);    
        end
        else
            `uvm_error("IP.DBG", $sformatf("[%s randomize fail]", get_full_name()))
    end
endtask : rand_dly

task nr_l2dl_base_seq::reg_rand_cfg(int max_dly_cyc=0);
    string regs_q[$];

    regs_q.delete();
    foreach(reg_data_aa[REG_NAME])
        regs_q.push_back(REG_NAME);


    foreach(regs_q[i]) begin
        string REG_NAME=regs_q[i];
        rand_dly(max_dly_cyc);
        write_reg_by_name(REG_NAME, reg_data_aa[REG_NAME]);
    end
endtask : reg_rand_cfg

`endif


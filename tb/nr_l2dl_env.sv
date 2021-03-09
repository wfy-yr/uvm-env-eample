// =========================================================================== //
// Author       : fengyangwu - ASR
// Last modified: 2020-07-09 19:00
// Filename     : nr_l2dl_env.sv
// Description  : 
// =========================================================================== //
`ifndef NR_L2DL_ENV_SV
`define NR_L2DL_ENV_SV


class nr_l2dl_env extends uvm_env;
    virtual nr_l2dl_top_intf        nr_l2dl_top_vif;

    // ambe uvc
    //nr_l2dl_amba_env                m_nr_l2dl_amba_env;
    rx_mac_env                      m_rx_mac_env;    

    //env configure
    nr_l2dl_env_cfg                 m_nr_l2dl_env_cfg;

    //scoreboard
    nr_l2dl_scb                     m_nr_l2dl_scb;

    //ref model
    nr_l2dl_ref_model               m_nr_l2dl_ref_model;

    //coverage
    nr_l2dl_coverage                m_nr_l2dl_coverage;

    // //user uvc
    rx_mac_tb_cmd_agent             m_nr_l2dl_tb_cmd_agent;
     //dtc_cmd_fifo
    //asr_dst_fifo_agent              m_nr_l2dl_dtc_cmd_agent;
     //dma
    rx_mac_dma_agent                m_nr_l2dl_dtc_dma_agent;
    rx_mac_dma_agent                m_nr_l2dl_mac_dma_agent;
    //dtc
    nr_l2dl_dtc_pld_agent           m_nr_l2dl_dtc_pld_agent;
    nr_l2dl_dtc_rdma_agent       m_nr_l2dl_dtc_rdma_agent;
    //rx_mac_dma_agent                m_nr_l2dl_mac_l2mce_dma_agent;
    //rx_mac_dma_agent                m_nr_l2dl_mac_l1tbinfo_dma_agent;
    //rx_mac_dma_agent                m_nr_l2dl_mac_l2tbinfo_dma_agent;
    //l1 mce
    //nr_l2dl_mce_agent                m_nr_l2dl_l1_mce_agent;
    //l2 mce
    //nr_l2dl_mce_agent                m_nr_l2dl_l2_mce_agent;
    //dl node0
    //nr_l2dl_dl_node0_agent           m_nr_l2dl_dl_node0_agent;
    //reg model
    rx_mac_l1_top__type             m_nr_l2dl_l1_reg_model;
    rx_mac_l2_top__type             m_nr_l2dl_l2_reg_model;
    // reg bus agent
    regbus_agent                    l1_reg_agent;
    regbus_agent                    l2_reg_agent;
    regbus_agent                    l2_blkaddr_agent;

    regbus_adapter                  l1_reg_sqr_adapter,l2_reg_sqr_adapter;
    regbus_adapter                  l1_mon_reg_adapter,l2_mon_reg_adapter;

    uvm_reg_predictor#(regbus_item) l1_reg_predictor,l2_reg_predictor;
    

    uvm_queue#(uvm_reg_block)       reg_model_queue;
    uvm_queue#(string)              blk_hier_queue;
    uvm_queue#(string)              map_name_queue;

    string  hdl_path;

    `uvm_component_utils_begin(nr_l2dl_env)
        `uvm_field_object(m_nr_l2dl_env_cfg, UVM_DEFAULT)
    `uvm_component_utils_end    
    // function and task

    function new(string name = "nr_l2dl_env", uvm_component parent);
        super.new(name,parent);
    endfunction

    extern function void config_reg_model();
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual function void connect_phase(uvm_phase phase);
    extern virtual function void end_of_elaboration_phase(uvm_phase phase);
endclass

function void nr_l2dl_env::build_phase(uvm_phase phase); // {{{
    super.build_phase(phase);

    `uvm_info($sformatf("%25s", get_name()), $sformatf("build_phase begin"), UVM_LOW)

    if(!uvm_config_db#(virtual nr_l2dl_top_intf)::get(this, "", "vif", nr_l2dl_top_vif)) begin
        `uvm_fatal("NOCFG", $sformatf("[%s] Cannot get nr_l2dl_top_vif", get_full_name()))
    end      


    if(!uvm_config_db#(nr_l2dl_env_cfg)::get(this, "", "m_nr_l2dl_env_cfg", m_nr_l2dl_env_cfg)) begin
        `uvm_fatal("IP.nr_l2dl", $sformatf("[%s] Cannot get nr_l2dl_env_cfg", get_full_name()))
    end      

    uvm_config_db#(nr_l2dl_env_cfg)::set(this, "*", "m_nr_l2dl_env_cfg", m_nr_l2dl_env_cfg);

    //trans type override
    //set_inst_override_by_type("m_nr_l2dl_tb_info_start_addr_agent.mon.*", nr_l2dl_fifo_trans::get_type(), nr_l2dl_tb_info_start_addr::get_type());
    
    //build amba_env
    //if(m_nr_l2dl_env_cfg.amba_env_en) begin
    //    m_nr_l2dl_amba_env     = nr_l2dl_amba_env::type_id::create("m_nr_l2dl_amba_env", this);
    //    uvm_config_db#(nr_l2dl_amba_env_cfg)::set(this,     "m_nr_l2dl_amba_env",     "cfg", m_nr_l2dl_env_cfg.m_nr_l2dl_amba_cfg);
    //end

    if(m_nr_l2dl_env_cfg.rx_mac_env_en) begin
        m_rx_mac_env     = rx_mac_env::type_id::create("m_rx_mac_env", this);
        uvm_config_db#(rx_mac_env_cfg)::set(this,     "m_rx_mac_env",     "m_rx_mac_env_cfg", m_nr_l2dl_env_cfg.m_rx_mac_env_cfg);
    end

    if(m_nr_l2dl_env_cfg.scb_en) begin
        //NR_L2DL_SCB_STREAM_ID_T id= id.first();
        int unsigned stream_id[$];
        string name[$];

        m_nr_l2dl_scb = nr_l2dl_scb::type_id::create("m_nr_l2dl_scb", this);
        m_nr_l2dl_scb.set_scb_property(nr_l2dl_scb::BI_DIR, nr_l2dl_scb::IN_ORDER, nr_l2dl_scb::EXACT_CHK);

        traverse_nr_l2dl_stream_name(stream_id, name);
        foreach(stream_id[ii]) begin
            m_nr_l2dl_scb.set_stream_name(stream_id[ii], name[ii]);
        end
    end

    //build ref_model
    if(m_nr_l2dl_env_cfg.ref_model_en) begin
        m_nr_l2dl_ref_model = nr_l2dl_ref_model::type_id::create("m_nr_l2dl_ref_model", this);
    end

    //build coverage
    m_nr_l2dl_coverage = new("m_nr_l2dl_coverage");
    uvm_config_db#(nr_l2dl_coverage)::set(this,     "*",     "m_nr_l2dl_coverage", m_nr_l2dl_coverage);
    //m_nr_l2dl_coverage.sample_reg_cfg(m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg);
    //m_nr_l2dl_coverage.sample_lc_cfg(m_nr_l2dl_env_cfg.lc_cfg[0]);
    //uvc
    if(m_nr_l2dl_env_cfg.nr_l2dl_tb_cmd_agent_en) begin
        m_nr_l2dl_tb_cmd_agent     = rx_mac_tb_cmd_agent::type_id::create("m_nr_l2dl_tb_cmd_agent", this);
        uvm_config_db#(rx_mac_tb_cmd_agent_cfg)::set(this,     "m_nr_l2dl_tb_cmd_agent",     "cfg", m_nr_l2dl_env_cfg.m_nr_l2dl_tb_cmd_agent_cfg);
    end

    //if(m_nr_l2dl_env_cfg.nr_l2dl_l1_mce_agent_en) begin
    //    m_nr_l2dl_l1_mce_agent     = nr_l2dl_mce_agent::type_id::create("m_nr_l2dl_l1_mce_agent", this);
    //    uvm_config_db#(nr_l2dl_mce_agent_cfg)::set(this,     "m_nr_l2dl_l1_mce_agent",     "cfg", m_nr_l2dl_env_cfg.m_nr_l2dl_l1_mce_agent_cfg);
    //end

    //if(m_nr_l2dl_env_cfg.nr_l2dl_l2_mce_agent_en) begin
    //    m_nr_l2dl_l2_mce_agent     = nr_l2dl_mce_agent::type_id::create("m_nr_l2dl_l2_mce_agent", this);
    //    uvm_config_db#(nr_l2dl_mce_agent_cfg)::set(this,     "m_nr_l2dl_l2_mce_agent",     "cfg", m_nr_l2dl_env_cfg.m_nr_l2dl_l2_mce_agent_cfg);
    //end

    //if(m_nr_l2dl_env_cfg.nr_l2dl_dl_node0_agent_en) begin
    //    m_nr_l2dl_dl_node0_agent     = nr_l2dl_dl_node0_agent::type_id::create("m_nr_l2dl_dl_node0_agent", this);
    //    uvm_config_db#(nr_l2dl_dl_node0_agent_cfg)::set(this,     "m_nr_l2dl_dl_node0_agent",     "cfg", m_nr_l2dl_env_cfg.m_nr_l2dl_dl_node0_agent_cfg);
    //end

    if(m_nr_l2dl_env_cfg.nr_l2dl_dtc_dma_agent_en) begin
        m_nr_l2dl_dtc_dma_agent     = rx_mac_dma_agent::type_id::create("m_nr_l2dl_dtc_dma_agent", this);
        uvm_config_db#(rx_mac_dma_agent_cfg)::set(this,     "m_nr_l2dl_dtc_dma_agent",     "cfg", m_nr_l2dl_env_cfg.m_nr_l2dl_dtc_dma_agent_cfg);
    end

    if(m_nr_l2dl_env_cfg.nr_l2dl_mac_dma_agent_en) begin
        m_nr_l2dl_mac_dma_agent     = rx_mac_dma_agent::type_id::create("m_nr_l2dl_mac_dma_agent", this);
        uvm_config_db#(rx_mac_dma_agent_cfg)::set(this,     "m_nr_l2dl_mac_dma_agent",     "cfg", m_nr_l2dl_env_cfg.m_nr_l2dl_mac_dma_agent_cfg);
    end

    if(m_nr_l2dl_env_cfg.nr_l2dl_dtc_pld_agent_en) begin
        m_nr_l2dl_dtc_pld_agent     = nr_l2dl_dtc_pld_agent::type_id::create("m_nr_l2dl_dtc_pld_agent", this);
        uvm_config_db#(nr_l2dl_dtc_pld_agent_cfg)::set(this,     "m_nr_l2dl_dtc_pld_agent",     "cfg", m_nr_l2dl_env_cfg.m_nr_l2dl_dtc_pld_agent_cfg);
    end

    if(m_nr_l2dl_env_cfg.nr_l2dl_dtc_rdma_agent_en) begin
        m_nr_l2dl_dtc_rdma_agent     = nr_l2dl_dtc_rdma_agent::type_id::create("m_nr_l2dl_dtc_rdma_agent", this);
        uvm_config_db#(nr_l2dl_dtc_rdma_agent_cfg)::set(this,     "m_nr_l2dl_dtc_rdma_agent",     "cfg", m_nr_l2dl_env_cfg.m_nr_l2dl_dtc_rdma_agent_cfg);
    end
    //if(m_nr_l2dl_env_cfg.nr_l2dl_mac_l2mce_dma_agent_en) begin
    //    m_nr_l2dl_mac_l2mce_dma_agent     = rx_mac_dma_agent::type_id::create("m_nr_l2dl_mac_l2mce_dma_agent", this);
    //    uvm_config_db#(rx_mac_dma_agent_cfg)::set(this,     "m_nr_l2dl_mac_l2mce_dma_agent",     "cfg", m_nr_l2dl_env_cfg.m_nr_l2dl_mac_l2mce_dma_agent_cfg);
    //end

    //if(m_nr_l2dl_env_cfg.nr_l2dl_mac_l1tbinfo_dma_agent_en) begin
    //    m_nr_l2dl_mac_l1tbinfo_dma_agent     = rx_mac_dma_agent::type_id::create("m_nr_l2dl_mac_l1tbinfo_dma_agent", this);
    //    uvm_config_db#(rx_mac_dma_agent_cfg)::set(this,     "m_nr_l2dl_mac_l1tbinfo_dma_agent",     "cfg", m_nr_l2dl_env_cfg.m_nr_l2dl_mac_l1tbinfo_dma_agent_cfg);
    //end

    //if(m_nr_l2dl_env_cfg.nr_l2dl_mac_l2tbinfo_dma_agent_en) begin
    //    m_nr_l2dl_mac_l2tbinfo_dma_agent     = rx_mac_dma_agent::type_id::create("m_nr_l2dl_mac_l2tbinfo_dma_agent", this);
    //    uvm_config_db#(rx_mac_dma_agent_cfg)::set(this,     "m_nr_l2dl_mac_l2tbinfo_dma_agent",     "cfg", m_nr_l2dl_env_cfg.m_nr_l2dl_mac_l2tbinfo_dma_agent_cfg);
    //end
    //uvc
    //if(m_nr_l2dl_env_cfg.nr_l2dl_dtc_cmd_agent_en) begin
    //    m_nr_l2dl_dtc_cmd_agent     = nr_l2dl_dst_fifo_agent::type_id::create("m_nr_l2dl_dtc_cmd_agent", this);
    //    uvm_config_db#(nr_l2dl_dst_fifo_agent_cfg)::set(this,     "m_nr_l2dl_dtc_cmd_agent",     "cfg", m_nr_l2dl_env_cfg.m_nr_l2dl_dtc_cmd_agent_cfg);
    //end

    if(m_nr_l2dl_env_cfg.l1_reg_agent_en) begin
        l1_reg_agent = regbus_agent::type_id::create("l1_reg_agent", this);
        l1_reg_sqr_adapter = regbus_adapter::type_id::create("l1_reg_sqr_adapter", this);
        l1_mon_reg_adapter = regbus_adapter::type_id::create("l1_mon_reg_adapter", this);
        l1_reg_predictor = new("l1_reg_predictor", this);
    end

    if(m_nr_l2dl_env_cfg.l2_reg_agent_en) begin
        l2_reg_agent = regbus_agent::type_id::create("l2_reg_agent", this);
        l2_reg_sqr_adapter = regbus_adapter::type_id::create("l2_reg_sqr_adapter", this);
        l2_mon_reg_adapter = regbus_adapter::type_id::create("l2_mon_reg_adapter", this);
        l2_reg_predictor = new("l2_reg_predictor", this);
    end

    if(m_nr_l2dl_env_cfg.l2_blkaddr_agent_en) begin
        l2_blkaddr_agent = regbus_agent::type_id::create("l2_blkaddr_agent", this);
    end

    config_reg_model();

    nr_l2dl_top_vif.cfg_toggle = ~nr_l2dl_top_vif.cfg_toggle;
    `uvm_info($sformatf("%25s", get_name()), $sformatf("build_phase end"), UVM_LOW)
endfunction : build_phase // }}}

function void nr_l2dl_env::config_reg_model();
    reg_model_queue = new();
    blk_hier_queue = new();
    map_name_queue = new();

    begin
        string hdl_path;
        if(!uvm_config_db#(string)::get(this, "", "nr_l2dl_hdl_path", hdl_path)) begin
            `uvm_warning(get_full_name(),"no nr_l2dl_hdl_path received using get() method")
        end
         /** For the backdoor HDL path to the RTL slave registers */
        m_nr_l2dl_l1_reg_model = rx_mac_l1_top__type::type_id::create("m_nr_l2dl_l1_reg_model", this);
        m_nr_l2dl_l1_reg_model.configure(null,hdl_path);
        m_nr_l2dl_l1_reg_model.build();
        void'(m_nr_l2dl_l1_reg_model.set_coverage(UVM_CVR_ALL));
        m_nr_l2dl_l1_reg_model.reset("HARD");
        m_nr_l2dl_l1_reg_model.default_path = UVM_FRONTDOOR;
        `uvm_info(get_type_name(), $sformatf("start lock reg_model"), UVM_NONE)
        m_nr_l2dl_l1_reg_model.lock_model();
        `uvm_info(get_type_name(), $sformatf("after lock reg_model %s",m_nr_l2dl_l1_reg_model.default_map.sprint()), UVM_NONE)

        reg_model_queue.push_back(m_nr_l2dl_l1_reg_model);
        blk_hier_queue.push_back("");
        map_name_queue.push_back("default_map");

        m_nr_l2dl_l2_reg_model = rx_mac_l2_top__type::type_id::create("m_nr_l2dl_l2_reg_model", this);
        m_nr_l2dl_l2_reg_model.configure(null,hdl_path);
        m_nr_l2dl_l2_reg_model.build();
        void'(m_nr_l2dl_l2_reg_model.set_coverage(UVM_CVR_ALL));
        m_nr_l2dl_l2_reg_model.reset("HARD");
        m_nr_l2dl_l2_reg_model.default_path = UVM_FRONTDOOR;
        `uvm_info(get_type_name(), $sformatf("start lock reg_model"), UVM_NONE)
        m_nr_l2dl_l2_reg_model.lock_model();
        `uvm_info(get_type_name(), $sformatf("after lock reg_model %s",m_nr_l2dl_l2_reg_model.default_map.sprint()), UVM_NONE)

        reg_model_queue.push_back(m_nr_l2dl_l2_reg_model);
        blk_hier_queue.push_back("");
        map_name_queue.push_back("default_map");
        /** For the backdoor HDL path to the RTL slave registers */
        //uvm_config_db #(nr_l2dl_top__type)::set(this, env.l1_reg_agent.get_full_name(), "nr_l2dl_reg_model", m_nr_l2dl_reg_model);
        //uvm_config_db #(nr_l2dl_top__type)::set(this, env.l2_reg_agent.get_full_name(), "nr_l2dl_reg_model", m_nr_l2dl_reg_model);
        //uvm_config_db #(uvm_object_wrapper)::set(this, {env.l1_reg_agent.get_full_name(), ".", "seqr.reset_phase"}, "default_sequence", regbus_reset_sequence::get_type());
        //uvm_config_db #(uvm_object_wrapper)::set(this, {env.l2_reg_agent.get_full_name(), ".", "seqr.reset_phase"}, "default_sequence", regbus_reset_sequence::get_type());

        uvm_config_db #(uvm_queue#(uvm_reg_block))::set(this, "*", "reg_model_queue", reg_model_queue);
        uvm_config_db #(uvm_queue#(string))::set(this, "*", "blk_hier_queue", blk_hier_queue);
        uvm_config_db #(uvm_queue#(string))::set(this, "*", "map_name_queue", map_name_queue);
        uvm_config_db #(uvm_reg_block)::set(this, "*", "l1_reg_model", m_nr_l2dl_l1_reg_model);
        uvm_config_db #(uvm_reg_block)::set(this, "*", "l2_reg_model", m_nr_l2dl_l2_reg_model);
        //uvm_config_db #(uvm_object_wrapper)::set(this, vseqr.main_phase, "default_sequence", `VSEQ::type_id::get());
    end
endfunction: config_reg_model

function void nr_l2dl_env::connect_phase(uvm_phase phase); // {{{
    super.connect_phase(phase);

    //connect with scb
    if(m_nr_l2dl_env_cfg.scb_en && m_nr_l2dl_env_cfg.scb_conn_en) begin
        //eg: if(m_nr_l2dl_env_cfg.nr_l2dl_in_agent_en) begin
        //        m_nr_l2dl_in_agent.mon.mon_port.connect(m_nr_l2dl_scb.insert_export);
        //    end
        //if(m_nr_l2dl_env_cfg.nr_l2dl_l1_mce_agent_en) begin
        //    m_nr_l2dl_l1_mce_agent.mon.mon_port.connect(m_nr_l2dl_scb.insert_export);
        //end

        //if(m_nr_l2dl_env_cfg.nr_l2dl_l2_mce_agent_en) begin
        //    m_nr_l2dl_l2_mce_agent.mon.mon_port.connect(m_nr_l2dl_scb.insert_export);
        //end

        if(m_nr_l2dl_env_cfg.nr_l2dl_mac_dma_agent_en) begin
            m_nr_l2dl_mac_dma_agent.mon.mon_port0.connect(m_nr_l2dl_scb.insert_export);
            m_nr_l2dl_mac_dma_agent.mon.mon_port1.connect(m_nr_l2dl_scb.insert_export);
            m_nr_l2dl_mac_dma_agent.mon.mon_port2.connect(m_nr_l2dl_scb.insert_export);
            m_nr_l2dl_mac_dma_agent.mon.mon_port3.connect(m_nr_l2dl_scb.insert_export);
            m_nr_l2dl_mac_dma_agent.mon.mon_port4.connect(m_nr_l2dl_scb.insert_export);
            m_nr_l2dl_mac_dma_agent.mon.mon_port5.connect(m_nr_l2dl_scb.insert_export);
            m_nr_l2dl_mac_dma_agent.mon.mon_port6.connect(m_nr_l2dl_scb.insert_export);
            m_nr_l2dl_mac_dma_agent.mon.mon_port7.connect(m_nr_l2dl_scb.insert_export);
            m_nr_l2dl_mac_dma_agent.mon.mon_port8.connect(m_nr_l2dl_scb.insert_export);
        end

        if(m_nr_l2dl_env_cfg.nr_l2dl_dtc_pld_agent_en) begin
            m_nr_l2dl_dtc_pld_agent.mon.mon_port.connect(m_nr_l2dl_scb.insert_export);
        end

        if(m_nr_l2dl_env_cfg.nr_l2dl_dtc_rdma_agent_en) begin
            m_nr_l2dl_dtc_rdma_agent.mon.mon_port.connect(m_nr_l2dl_scb.insert_export);
        end
        //if(m_nr_l2dl_env_cfg.nr_l2dl_mac_l2mce_dma_agent_en) begin
        //    m_nr_l2dl_mac_l2mce_dma_agent.mon.mon_port.connect(m_nr_l2dl_scb.insert_export);
        //end

        //if(m_nr_l2dl_env_cfg.nr_l2dl_mac_l1tbinfo_dma_agent_en) begin
        //    m_nr_l2dl_mac_l1tbinfo_dma_agent.mon.mon_port.connect(m_nr_l2dl_scb.insert_export);
        //end

        //if(m_nr_l2dl_env_cfg.nr_l2dl_mac_l2tbinfo_dma_agent_en) begin
        //    m_nr_l2dl_mac_l2tbinfo_dma_agent.mon.mon_port.connect(m_nr_l2dl_scb.insert_export);
        //end

        if(m_nr_l2dl_env_cfg.ref_model_en) begin
            m_nr_l2dl_ref_model.exp_ap.connect(m_nr_l2dl_scb.expect_export);
        end
    end

    //connect with ref model
    if(m_nr_l2dl_env_cfg.ref_model_en && m_nr_l2dl_env_cfg.ref_model_conn_en) begin
        //eg: if(m_nr_l2dl_env_cfg.nr_l2dl_in_agent_en) begin
        //        m_nr_l2dl_in_agent.mon.mon_port.connect(m_nr_l2dl_ref_model.mac_in_fifo.analysis_export);
        //    end
        if(m_nr_l2dl_env_cfg.nr_l2dl_tb_cmd_agent_en) begin
            m_nr_l2dl_tb_cmd_agent.mon.mon_port_base.connect(m_nr_l2dl_ref_model.tb_cmd_fifo_port.analysis_export);
        end
    end
    if(m_nr_l2dl_env_cfg.l1_reg_agent_en) begin
        m_nr_l2dl_l1_reg_model.default_map.set_sequencer(l1_reg_agent.seqr,l1_reg_sqr_adapter);
        m_nr_l2dl_l1_reg_model.default_map.set_auto_predict(1);
        l1_reg_predictor.map  = m_nr_l2dl_l1_reg_model.default_map;
        l1_reg_predictor.adapter  = l1_mon_reg_adapter;
        l1_reg_agent.mon.analysis_port.connect(l1_reg_predictor.bus_in);
    end
    if(m_nr_l2dl_env_cfg.l2_reg_agent_en) begin
        m_nr_l2dl_l2_reg_model.default_map.set_sequencer(l2_reg_agent.seqr,l2_reg_sqr_adapter);
        m_nr_l2dl_l2_reg_model.default_map.set_auto_predict(1);
        l2_reg_predictor.map  = m_nr_l2dl_l2_reg_model.default_map;
        l2_reg_predictor.adapter  = l2_mon_reg_adapter;
        l2_reg_agent.mon.analysis_port.connect(l2_reg_predictor.bus_in);
    end
endfunction : connect_phase // }}}

function void nr_l2dl_env::end_of_elaboration_phase(uvm_phase phase); // {{{
    super.end_of_elaboration_phase(phase);

endfunction : end_of_elaboration_phase //}}}

`endif


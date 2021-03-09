`ifndef NR_L2DL_DTC_RDMA_COVERAGE__SV
`define NR_L2DL_DTC_RDMA_COVERAGE__SV 

class nr_l2dl_dtc_rdma_coverage;
    
    nr_l2dl_dtc_rdma_trans tr;
    nr_l2dl_dtc_rdma_agent_cfg cfg;

    covergroup nr_l2dl_dtc_rdma_tr_cg;
        option.per_instance = 1;
        //coverpoint tr.a;
        //
    endgroup

    covergroup nr_l2dl_dtc_rdma_agent_cfg_cg;
        option.per_instance = 1;
        //coverpoint cfg.a;
        //
    endgroup

    function new(string name);
        nr_l2dl_dtc_rdma_tr_cg=new();
        nr_l2dl_dtc_rdma_agent_cfg_cg=new();
        nr_l2dl_dtc_rdma_tr_cg.set_inst_name({name, ".nr_l2dl_dtc_rdma_tr_cg"});
        nr_l2dl_dtc_rdma_agent_cfg_cg.set_inst_name({name, ".nr_l2dl_dtc_rdma_agent_cfg_cg"});
    endfunction

    virtual function void sample_tr(nr_l2dl_dtc_rdma_trans tr);
        this.tr=tr;
        nr_l2dl_dtc_rdma_tr_cg.sample();
    endfunction

    virtual function void sample_cfg(nr_l2dl_dtc_rdma_agent_cfg cfg);
        this.cfg=cfg;
        nr_l2dl_dtc_rdma_agent_cfg_cg.sample();
    endfunction
endclass

`endif

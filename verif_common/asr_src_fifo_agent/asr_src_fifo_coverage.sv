`ifndef ASR_SRC_FIFO_COVERAGE__SV
`define ASR_SRC_FIFO_COVERAGE__SV 

class asr_src_fifo_coverage;
    
    asr_src_fifo_trans tr;
    asr_src_fifo_agent_cfg cfg;

    covergroup asr_src_fifo_tr_cg;
        option.per_instance = 1;
        //coverpoint tr.a;
        //
    endgroup

    covergroup asr_src_fifo_agent_cfg_cg;
        option.per_instance = 1;
        //coverpoint cfg.a;
        //
    endgroup

    function new(string name);
        asr_src_fifo_tr_cg=new();
        asr_src_fifo_agent_cfg_cg=new();
        asr_src_fifo_tr_cg.set_inst_name({name, ".asr_src_fifo_tr_cg"});
        asr_src_fifo_agent_cfg_cg.set_inst_name({name, ".asr_src_fifo_agent_cfg_cg"});
    endfunction

    virtual function void sample_tr(asr_src_fifo_trans tr);
        this.tr=tr;
        asr_src_fifo_tr_cg.sample();
    endfunction

    virtual function void sample_cfg(asr_src_fifo_agent_cfg cfg);
        this.cfg=cfg;
        asr_src_fifo_agent_cfg_cg.sample();
    endfunction
endclass

`endif

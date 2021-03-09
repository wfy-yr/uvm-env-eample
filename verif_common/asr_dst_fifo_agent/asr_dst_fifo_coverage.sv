`ifndef ASR_DST_FIFO_COVERAGE__SV
`define ASR_DST_FIFO_COVERAGE__SV 

class asr_dst_fifo_coverage;
    
    asr_dst_fifo_trans tr;
    asr_dst_fifo_agent_cfg cfg;

    covergroup asr_dst_fifo_tr_cg;
        option.per_instance = 1;
        //coverpoint tr.a;
        //
    endgroup

    covergroup asr_dst_fifo_agent_cfg_cg;
        option.per_instance = 1;
        //coverpoint cfg.a;
        //
    endgroup

    function new(string name);
        asr_dst_fifo_tr_cg=new();
        asr_dst_fifo_agent_cfg_cg=new();
        asr_dst_fifo_tr_cg.set_inst_name({name, ".asr_dst_fifo_tr_cg"});
        asr_dst_fifo_agent_cfg_cg.set_inst_name({name, ".asr_dst_fifo_agent_cfg_cg"});
    endfunction

    virtual function void sample_tr(asr_dst_fifo_trans tr);
        this.tr=tr;
        asr_dst_fifo_tr_cg.sample();
    endfunction

    virtual function void sample_cfg(asr_dst_fifo_agent_cfg cfg);
        this.cfg=cfg;
        asr_dst_fifo_agent_cfg_cg.sample();
    endfunction
endclass

`endif

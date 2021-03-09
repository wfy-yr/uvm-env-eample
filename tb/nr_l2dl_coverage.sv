`ifndef NR_L2DL_COVERAGE__SV
`define NR_L2DL_COVERAGE__SV 

class nr_l2dl_coverage;
    
    rx_mac_reg_cfg reg_cfg;
    nr_l2dl_lc_cfg lc_cfg;
    rx_mac_dl_node0 dl_node0;
    rx_mac_mce_node mce_node;
    `include "covgrp_def.sv"

    function new(string name);
    `include "covgrp_new.sv"
    endfunction

    virtual function void sample_reg_cfg(rx_mac_reg_cfg reg_cfg);
        this.reg_cfg=reg_cfg;
        nr_l2dl_reg_cg.sample();
    endfunction

    virtual function void sample_lc_cfg(nr_l2dl_lc_cfg lc_cfg);
        this.lc_cfg=lc_cfg;
        nr_l2dl_lc_cfg_cg.sample();
    endfunction

    virtual function void sample_dl_node0(rx_mac_dl_node0 dl_node0);
        this.dl_node0=dl_node0;
        nr_l2dl_dl_node0_cg.sample();
    endfunction

    virtual function void sample_mce_node(rx_mac_mce_node mce_node);
        this.mce_node=mce_node;
        nr_l2dl_mce_cg.sample();
    endfunction
endclass

`endif

`ifndef RX_MAC_REG_CFG__SV 
`define RX_MAC_REG_CFG__SV 
class rx_mac_reg_cfg extends uvm_object;
    //rand bit ;
    //l2 reg
    rand bit [15:0]  dbg_out_len;
    rand bit         tb_dbgout_en;
    rand bit         rxmac_work_en;
    rand bit [5:0]   seg_buf_size;
    rand bit [1:0]   asmb_seg_type;
    rand bit         macce_dec_en;
    rand bit [15:0]  macce_dec_bits;

    rand bit         l2_tbinfo_idx_latch;
    rand bit         l2_tbinfo_idx_clr;
    rand bit         l2_tbinfo_sync_st_clr;

    rand bit         byte_inv_en;
    rand bit         bit_inv_en;
    rand bit         dtc_aucg_en;


    rand bit [1:0]   blk_size;
    rand bit         blkaddr_fifo_clr;

    rand bit         lgch_cfg_done;

    `uvm_object_utils_begin(rx_mac_reg_cfg)
        //`uvm_field_object(m_rx_mac_amba_env_cfg, UVM_DEFAULT)
        //eg : `uvm_field_object(m_rx_mac_in_agent_cfg, UVM_DEFAULT)
        //`uvm_field_int(amba_env_en, UVM_DEFAULT)
        `uvm_field_int(dbg_out_len, UVM_DEFAULT)
        `uvm_field_int(tb_dbgout_en, UVM_DEFAULT)
        `uvm_field_int(rxmac_work_en, UVM_DEFAULT)
        `uvm_field_int(seg_buf_size, UVM_DEFAULT)
        `uvm_field_int(asmb_seg_type, UVM_DEFAULT)
        `uvm_field_int(macce_dec_en, UVM_DEFAULT)
        `uvm_field_int(macce_dec_bits, UVM_DEFAULT)
        `uvm_field_int(l2_tbinfo_idx_latch, UVM_DEFAULT)
        `uvm_field_int(l2_tbinfo_idx_clr, UVM_DEFAULT)
        `uvm_field_int(l2_tbinfo_sync_st_clr, UVM_DEFAULT)
        `uvm_field_int(blk_size, UVM_DEFAULT)
        `uvm_field_int(blkaddr_fifo_clr, UVM_DEFAULT)
        `uvm_field_int(byte_inv_en, UVM_DEFAULT)
        `uvm_field_int(bit_inv_en, UVM_DEFAULT)
        `uvm_field_int(dtc_aucg_en, UVM_DEFAULT)
        `uvm_field_int(lgch_cfg_done, UVM_DEFAULT)
    `uvm_object_utils_end                   
endclass : rx_mac_reg_cfg
`endif

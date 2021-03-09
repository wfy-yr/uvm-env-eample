`ifndef NR_L2DL_LC_CFG__SV 
`define NR_L2DL_LC_CFG__SV 
class nr_l2dl_lc_cfg extends uvm_object;
    //rand bit ;
    typedef enum bit [1:0] {
        RLC_AM = 0,
        RLC_UM,
        RLC_TM
    } RLC_MODE_T;

    typedef enum bit [1:0] {
        RLC_SN_6 = 0,
        RLC_SN_12,
        RLC_SN_18,
        RLC_SN_NA
    } RLC_SN_LEN_T;

    typedef enum bit {
        DRB = 0,
        SRB
    } RB_TYPE_T;

    typedef enum bit {
        PDCP_SN_12 = 0,
        PDCP_SN_18
    } PDCP_SN_LEN_T;

    typedef enum bit {
        LGCH_DEACTIVE = 0,
        LGCH_ACTIVE
    } LGCH_ACTIVE_T;

    typedef enum bit {
        SFT_DTC = 0,
        SFT_NO_DTC 
    } SFT_DTC_T;

    typedef enum bit {
        NO_HDR = 0,
        HDR 
    } SDAP_HDR_PRESENT_T;

    typedef enum bit {
        CIP_NO_PRESENT = 0,
        CIP_PRESENT 
    } CIP_PRESENT_T;

    typedef enum bit [1:0] {
        NEA0 = 0,
        NEA1, 
        NEA2, 
        NEA3 
    } DTC_DECIP_ALGO_T;

    typedef enum bit {
        INTEGRITY_NO_PRESENT = 0,
        INTEGRITY_PRESENT
    } INT_PRESENT_T;

    typedef enum bit [1:0] {
        NIA1 = 2'h1,
        NIA2, 
        NIA3 
    } DTC_DEINT_ALGO_T;

    typedef enum bit {
        NO_CP_HDR = 0,
        CP_HDR 
    } CP_HEADER_EN_T;

    rand RLC_MODE_T            rlc_mode;
    rand RLC_SN_LEN_T          rlc_sn_len;
    rand RB_TYPE_T             rb_type;
    rand PDCP_SN_LEN_T         pdcp_sn_len;     
    rand LGCH_ACTIVE_T         lgch_active;     
    rand SFT_DTC_T             sft_dtc;         
    rand SDAP_HDR_PRESENT_T    sdap_hdr_present;
    rand CIP_PRESENT_T         cip_present;
    rand DTC_DECIP_ALGO_T      dtc_decip_algo;
    rand INT_PRESENT_T         int_present;
    rand DTC_DEINT_ALGO_T      dtc_deint_algo;
    rand bit [7:0]             rb_id;
    rand bit [7:0]             resvd_intv_size;
    rand CP_HEADER_EN_T        cp_header_en;
    rand bit [17:0]            pdcp_window_size;
    rand bit [ 1:0]            key_idx;
    rand bit [11:0]            rsvd;
    
    int unsigned       sn_len_rlc;
    int unsigned       sn_len_pdcp;
    int unsigned       rlc_sn_modulo_base;
    int unsigned       pdcp_sn_modulo_base;
    bit [17:0]         rlc_sn_modulo_mask;
    bit [17:0]         pdcp_sn_modulo_mask;
    `uvm_object_utils_begin(nr_l2dl_lc_cfg)
        `uvm_field_enum(RLC_MODE_T, rlc_mode, UVM_ALL_ON)
        `uvm_field_enum(RLC_SN_LEN_T, rlc_sn_len, UVM_ALL_ON)
        `uvm_field_enum(RB_TYPE_T, rb_type, UVM_ALL_ON)
        `uvm_field_enum(PDCP_SN_LEN_T, pdcp_sn_len, UVM_ALL_ON)
        `uvm_field_enum(LGCH_ACTIVE_T, lgch_active, UVM_ALL_ON)
        `uvm_field_enum(SFT_DTC_T, sft_dtc, UVM_ALL_ON)
        `uvm_field_enum(SDAP_HDR_PRESENT_T, sdap_hdr_present, UVM_ALL_ON)
        `uvm_field_enum(CIP_PRESENT_T, cip_present, UVM_ALL_ON)
        `uvm_field_enum(DTC_DECIP_ALGO_T, dtc_decip_algo, UVM_ALL_ON)
        `uvm_field_enum(INT_PRESENT_T, int_present, UVM_ALL_ON)
        `uvm_field_enum(DTC_DEINT_ALGO_T, dtc_deint_algo, UVM_ALL_ON)
        `uvm_field_int(rb_id, UVM_ALL_ON)
        `uvm_field_int(resvd_intv_size, UVM_ALL_ON)
        `uvm_field_enum(CP_HEADER_EN_T, cp_header_en, UVM_ALL_ON)
        `uvm_field_int(pdcp_window_size, UVM_ALL_ON)
        `uvm_field_int(key_idx, UVM_ALL_ON)
        `uvm_field_int(rsvd, UVM_ALL_ON)
    `uvm_object_utils_end                   

    constraint rb_id_constrain{
        if(rb_type == DRB)
        {
            rb_id inside {[1:32]};
        }
        else
        {
            rb_id inside {[1:3]};
        }
        resvd_intv_size[2:0] == 'h0;
        solve rb_type before rb_id;
    }

    function new (string name = "nr_l2dl_lc_cfg");
        super.new(name);
    endfunction : new

    function void post_randomize();
        if(rlc_sn_len == RLC_SN_6) begin
            sn_len_rlc = 6;
        end
        else if(rlc_sn_len == RLC_SN_12) begin
            sn_len_rlc = 12;
        end
        else if(rlc_sn_len == RLC_SN_18) begin
            sn_len_rlc = 18;
        end
        else begin
            sn_len_rlc = 0;
        end
        rlc_sn_modulo_base = 1<<sn_len_rlc;
        rlc_sn_modulo_mask = rlc_sn_modulo_base - 1;

        if(pdcp_sn_len == PDCP_SN_12) begin
            sn_len_pdcp = 12;
        end
        else if(pdcp_sn_len == PDCP_SN_18) begin
            sn_len_pdcp = 18;
        end
        else begin
            sn_len_pdcp = 0;
        end
        pdcp_sn_modulo_base = 1<<sn_len_pdcp;
        pdcp_sn_modulo_mask = pdcp_sn_modulo_base - 1;
        pdcp_window_size = pdcp_sn_modulo_mask/2 + 1;
    endfunction

endclass : nr_l2dl_lc_cfg
`endif

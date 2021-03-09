class nr_l2dl_mac_pkt extends uvm_object;

// All the variable refer to 3GPP standard
    typedef enum {
        mac_pdu_l8,
        mac_pdu_l16,
        mac_ce_base,
        mac_ce_l8,
        mac_ce_l16,
        mac_error_lcid,
        mac_padding
    } mac_type;
    rand mac_type mc_type;
    rand bit      r;
    rand bit      f;

    rand bit [5:0]  lcid;
    rand bit [15:0] l;
    rand bit [5:0]  lcid_left;

    `uvm_object_utils_begin(nr_l2dl_mac_pkt)
        `uvm_field_int    (r,                  UVM_ALL_ON)
        `uvm_field_int    (f,                  UVM_ALL_ON)
        `uvm_field_int    (lcid,               UVM_ALL_ON)
        `uvm_field_int    (lcid_left,          UVM_ALL_ON)
        `uvm_field_int    (l,                  UVM_ALL_ON)
        `uvm_field_enum   (mac_type, mc_type,  UVM_ALL_ON)
    `uvm_object_utils_end

    function new (string name = "nr_l2dl_mac_pkt");
        super.new(name);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH)
    endfunction : new

    constraint mac_ce_cons {
        if(mc_type == mac_ce_base){
           lcid inside {[47:62]};
           lcid_left == lcid;
        }
        if(mc_type == mac_ce_l8){
           f == 0;
           lcid inside {[47:62]};
           l <= 255;
           l > 0;
           lcid_left == lcid;
        }
        if(mc_type == mac_ce_l16){
           f == 1;
           lcid inside {[47:62]};
           l <= 65535;
           l > 0;
           lcid_left == lcid;
        }
        if(mc_type == mac_pdu_l8){
           f == 0;
           lcid inside {[0:32]};
           l <= 255;
           l > 0;
        }
        if(mc_type == mac_pdu_l16){
           f == 1;
           lcid inside {[0:32]};
           l <= 65535;
           l > 255;
        }
        if(mc_type == mac_error_lcid){
           lcid inside {[33:46]};
           lcid_left == lcid;
        }
        if(mc_type == mac_padding){
           lcid inside {63};
           lcid_left == lcid;
        }
        solve mc_type before lcid;
        solve mc_type before f;
        solve mc_type before l;
        solve lcid before lcid_left;
    }


    extern virtual function void pack_hdr(bit dc_en, ref bit [7:0] byte_q[$], output bit [3:0] mac_hdr_l);
endclass

function void nr_l2dl_mac_pkt::pack_hdr(bit dc_en, ref bit [7:0] byte_q[$], output bit [3:0] mac_hdr_l);
    bit [7:0]   byte_0;

    if(dc_en == 0) byte_0 = {r, f, lcid};
    if(dc_en == 1) byte_0 = {r, f, lcid_left};
    byte_q.push_back(byte_0);

    if(mc_type inside {mac_ce_base}) begin
        mac_hdr_l = 1;
    end

    if(mc_type inside {mac_pdu_l8,mac_ce_l8}) begin
        mac_hdr_l = 2;
        byte_q.push_back(l[7:0]);
    end

    if(mc_type inside {mac_pdu_l16,mac_ce_l16}) begin
        mac_hdr_l = 3;
        byte_q.push_back(l[15:8]);
        byte_q.push_back(l[7:0]);
    end

    if(mc_type == mac_error_lcid) begin
        mac_hdr_l = 1;
    end

    if(mc_type == mac_padding) begin
        mac_hdr_l = 1;
    end
endfunction : pack_hdr


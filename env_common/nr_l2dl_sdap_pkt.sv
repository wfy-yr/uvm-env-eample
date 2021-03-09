class nr_l2dl_sdap_pkt extends uvm_object;

// All the variable refer to 3GPP standard
// RDI : Reflictive QoS flow to DRB mapping indication
// RQI : Reflictive QoS indication
// QFI : QoS flow ID

    typedef enum {
        sdap_normal,
        sdap_ctl
    } sdap_type;
    rand sdap_type sdap_type_sel;
    rand bit      rdi;
    rand bit      rqi;

    rand bit      r;
    rand bit      d_c;
    rand bit [5:0]  qfi;

    `uvm_object_utils_begin(nr_l2dl_sdap_pkt)
        `uvm_field_int    (rdi,                  UVM_ALL_ON)
        `uvm_field_int    (rqi,                  UVM_ALL_ON)
        `uvm_field_int    (r,                    UVM_ALL_ON)
        `uvm_field_int    (d_c,                  UVM_ALL_ON)
        `uvm_field_int    (qfi,                  UVM_ALL_ON)
        `uvm_field_enum   (sdap_type, sdap_type_sel,  UVM_ALL_ON)
    `uvm_object_utils_end

    function new (string name = "nr_l2dl_sdap_pkt");
        super.new(name);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH)
    endfunction : new

    constraint sdap_cons {
        if(sdap_type_sel == sdap_ctl){
           d_c == 0;
        }
        else if(sdap_type_sel == sdap_normal){
           d_c == 1;
        }
    }


    extern virtual function void pack_hdr(ref bit [7:0] byte_q[$], output bit [3:0] sdap_hdr_l);
endclass

function void nr_l2dl_sdap_pkt::pack_hdr(ref bit [7:0] byte_q[$], output bit [3:0] sdap_hdr_l);
    bit [7:0]   temp_hdr;

    if(sdap_type_sel == sdap_normal) begin
        temp_hdr[7:0] = {rdi,rqi,qfi};
        sdap_hdr_l = 1;
        byte_q.push_back(temp_hdr);
    end

    if(sdap_type_sel == sdap_ctl) begin
        temp_hdr[7:0] = {d_c, r, qfi};
        sdap_hdr_l = 1;
        byte_q.push_back(temp_hdr);
    end

endfunction : pack_hdr


class nr_l2dl_pdcp_pkt extends uvm_object;

    // SN: sequence number
    // SRBs: signalling Radio Bearer Carrying Control Plane Data

    typedef enum {
        pdcp_ctl_pdu,
        pdcp_ctl_rohc,
        pdcp_dat_pdu_srb,
        pdcp_dat_pdu_drb_12,
        pdcp_dat_pdu_drb_18
    } pdcp_type;
    rand pdcp_type pdcp_type_sel;
    rand bit [17:0]     pdcp_sn;
    rand bit            r; //reserved bit
    rand bit            d_c; // 0:control, 1:data;
    rand bit [2:0]      pdu_type;
    rand bit [31:0]     maci_tail; // the tail part of gen

    `uvm_object_utils_begin(nr_l2dl_pdcp_pkt)
        `uvm_field_int    (r,                  UVM_ALL_ON)
        `uvm_field_int    (d_c,                UVM_ALL_ON)
        `uvm_field_int    (pdcp_sn,            UVM_ALL_ON)
        `uvm_field_int    (pdu_type,           UVM_ALL_ON)
        `uvm_field_int    (maci_tail,          UVM_ALL_ON)
        `uvm_field_enum   (pdcp_type, pdcp_type_sel,  UVM_ALL_ON)
    `uvm_object_utils_end

    function new (string name = "nr_l2dl_pdcp_pkt");
        super.new(name);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH)
    endfunction : new

    constraint ctl_pdu_pdcp {
        if(pdcp_type_sel == pdcp_ctl_pdu){
           d_c == 1'b0;
           pdu_type == 3'b000;
        }
        if(pdcp_type_sel == pdcp_ctl_rohc){
           d_c == 1'b0;
           pdu_type == 3'b001;
        }
    }

    constraint data_pdu_pdcp {
        if(pdcp_type_sel == pdcp_dat_pdu_srb){
           pdcp_sn <= 4095;
        }
        if(pdcp_type_sel == pdcp_dat_pdu_drb_12){
           d_c == 1'b1;
           pdcp_sn <= 4095;
        }
        if(pdcp_type_sel == pdcp_dat_pdu_drb_18){
           d_c == 1'b1;
           pdcp_sn <= 262143;
        }
    }

    extern virtual function void pack_hdr(ref bit [7:0] byte_q[$], output bit [3:0] pdcp_hdr_l);
    extern virtual function void pack_tail(ref bit [7:0] byte_q[$]);
endclass

function void nr_l2dl_pdcp_pkt::pack_hdr(ref bit [7:0] byte_q[$], output bit [3:0] pdcp_hdr_l);
    bit [23:0]   temp_hdr;


    if(pdcp_type_sel inside {pdcp_dat_pdu_srb}) begin
        pdcp_hdr_l = 2;
        temp_hdr[23:8] = {{4{r}}, pdcp_sn[11:0]};
        byte_q.push_back(temp_hdr[23:16]);
        byte_q.push_back(temp_hdr[15:8]);
    end

    if(pdcp_type_sel inside {pdcp_dat_pdu_drb_12}) begin
        pdcp_hdr_l = 2;
        temp_hdr[23:8] = {d_c, {3{r}}, pdcp_sn[11:0]};
        byte_q.push_back(temp_hdr[23:16]);
        byte_q.push_back(temp_hdr[15:8]);
    end

    if(pdcp_type_sel inside {pdcp_dat_pdu_drb_18}) begin
        pdcp_hdr_l = 3;
        temp_hdr[23:0] = {d_c, {5{r}}, pdcp_sn};
        byte_q.push_back(temp_hdr[23:16]);
        byte_q.push_back(temp_hdr[15:8]);
        byte_q.push_back(temp_hdr[7:0]);
    end
    
//---------------------control pdu------------------------------//
    if(pdcp_type_sel inside {pdcp_ctl_pdu}) begin
        pdcp_hdr_l = 1;
        temp_hdr[23:16] = {d_c, pdu_type, {4{r}}};
        byte_q.push_back(temp_hdr[23:16]);
    end
    if(pdcp_type_sel inside {pdcp_ctl_rohc}) begin
        pdcp_hdr_l = 1;
        temp_hdr[23:16] = {d_c, pdu_type, {4{r}}};
        byte_q.push_back(temp_hdr[23:16]);
    end
endfunction : pack_hdr

function void nr_l2dl_pdcp_pkt::pack_tail(ref bit [7:0]byte_q[$]);
    bit [31:0] temp_tail;
    if(pdcp_type_sel inside {pdcp_dat_pdu_srb,pdcp_dat_pdu_drb_12,pdcp_dat_pdu_drb_18}) begin
        temp_tail = maci_tail;
        byte_q.push_back(maci_tail[7:0]);
        byte_q.push_back(maci_tail[15:8]);
        byte_q.push_back(maci_tail[23:16]);
        byte_q.push_back(maci_tail[31:24]);
    end

endfunction : pack_tail


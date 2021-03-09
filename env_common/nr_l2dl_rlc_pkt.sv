class nr_l2dl_rlc_pkt extends uvm_object;

// All the variable refer to 3GPP standard
// SI: Segmenation info;
// SN: Sequence Num;
// SO: Segment offset;
// P : Polling bit;
// R : Resever bit;

    typedef enum {
        umd_pdu_base,
        umd_pdu_sn6,
        umd_pdu_sn12,
        umd_pdu_sn6_so16,
        umd_pdu_sn12_so16,
        amd_pdu_base,
        amd_pdu_sn18,
        amd_pdu_sn12_so16,
        amd_pdu_final,
        status_pdu
    } rlc_pdu;

    rand rlc_pdu rlc_pdu_type;
    rand bit [1:0]     si;
    rand bit [17:0]    sn;  // umd max size 12, amd max size 18;
    rand bit [15:0]    so;  //TODO, add constraint when si == 00;
    rand bit           d_c; //For AMD pdu;
    rand bit           r;   //RES, can be ignored
    rand bit           p;
    rand bit [2:0]     cpt; //3'b000 STATUS PDU, 3'b001 RES;

    `uvm_object_utils_begin(nr_l2dl_rlc_pkt)
        `uvm_field_int    (si,                  UVM_ALL_ON)
        `uvm_field_int    (sn,                  UVM_ALL_ON)
        `uvm_field_int    (so,                  UVM_ALL_ON)
        `uvm_field_int    (d_c,                 UVM_ALL_ON)
        `uvm_field_int    (r,                   UVM_ALL_ON)
        `uvm_field_int    (p,                   UVM_ALL_ON)
        `uvm_field_int    (cpt,                 UVM_ALL_ON)
        `uvm_field_enum   (rlc_pdu, rlc_pdu_type,  UVM_ALL_ON)
    `uvm_object_utils_end

    function new (string name = "nr_l2dl_rlc_pkt");
        super.new(name);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH)
    endfunction : new

    //constraint size_value {size%8 == 0;}
    constraint cpt_cons {cpt inside {3'b000, 3'b001};}
    
    //constraint for si in um part
    constraint si_um_rlc_type {
        if(rlc_pdu_type == umd_pdu_base){
           si == 2'b00;
        }
        if(rlc_pdu_type == umd_pdu_sn6){
           si == 2'b01;
           sn <= 63;
        }
        if(rlc_pdu_type == umd_pdu_sn12){
           si == 2'b01;
           sn <= 4095;
        }
        if(rlc_pdu_type == umd_pdu_sn6_so16){
           si inside {[2'b10:2'b11]};
           sn <= 63;
           so != 0;
        }
        if(rlc_pdu_type == umd_pdu_sn12_so16){
           si inside {[2'b10:2'b11]};
           sn <= 4095;
           so != 0;
        }
    }

    //constraint for si in am part
    constraint si_am_rlc_type {
        if(rlc_pdu_type == amd_pdu_base){
           d_c == 1'b1;
           si inside {[2'b00:2'b01]};
           sn <= 4095;
        }
        if(rlc_pdu_type == amd_pdu_sn18){
           d_c == 1'b1;
           si inside {[2'b00:2'b01]};
           sn <= 262143;
        }
        if(rlc_pdu_type == amd_pdu_sn12_so16){
           d_c == 1'b1;
           si inside {[2'b10:2'b11]};
           sn <= 4095;
           so != 0;
        }
        if(rlc_pdu_type == amd_pdu_final){
           d_c == 1'b1;
           si inside {[2'b10:2'b11]};
           sn <= 262143;
           so != 0;
        }
    }

    constraint status_cons{
        if(rlc_pdu_type == status_pdu){
           d_c == 1'b0;
           cpt == 3'b000;
        }
    }

    extern virtual function void pack_hdr(ref bit [7:0] byte_q[$], output bit [3:0] rlc_hdr_l);
endclass

function void nr_l2dl_rlc_pkt::pack_hdr(ref bit [7:0] byte_q[$], output bit [3:0] rlc_hdr_l);
    bit [31:0]   temp_hdr;
    bit [39:0]   temp_hdr_amd;
    //---------------um
    if(rlc_pdu_type == umd_pdu_base) begin
        temp_hdr[31:24] = {si, {6{r}}};
        rlc_hdr_l = 1;
        byte_q.push_back(temp_hdr[31:24]);
    end

    if(rlc_pdu_type inside umd_pdu_sn6) begin
        temp_hdr[31:24] = {si, sn[5:0]};
        rlc_hdr_l = 1;
        byte_q.push_back(temp_hdr[31:24]);
    end

    if(rlc_pdu_type inside umd_pdu_sn12) begin
        temp_hdr[31:16] = {si, {2{r}}, sn[11:0]};
        rlc_hdr_l = 2;
        byte_q.push_back(temp_hdr[31:24]);
        byte_q.push_back(temp_hdr[23:16]);
    end

    if(rlc_pdu_type == umd_pdu_sn6_so16) begin
        temp_hdr[31:8] = {si, sn[5:0], so};
        rlc_hdr_l = 3;
        for (int i=4; i>1; i--) begin
            byte_q.push_back(temp_hdr[(8*i-1)-:8]);
        end
    end

    if(rlc_pdu_type == umd_pdu_sn12_so16) begin
        temp_hdr[31:0] = {si, {2{r}}, sn[11:0], so};
        rlc_hdr_l = 4;
        for (int i=4; i>0; i--) begin
            byte_q.push_back(temp_hdr[(8*i-1)-:8]);
        end
    end
    
    //////////////amd
    if(rlc_pdu_type == amd_pdu_base) begin
        temp_hdr_amd[39:24] = {d_c, p, si, sn[11:0]};
        rlc_hdr_l = 2;
        byte_q.push_back(temp_hdr_amd[39:32]);
        byte_q.push_back(temp_hdr_amd[31:24]);
    end

    if(rlc_pdu_type == amd_pdu_sn18) begin
        temp_hdr_amd[39:16] = {d_c, p, si, {2{r}}, sn};
        rlc_hdr_l = 3;
        for (int i=5; i>2; i--) begin
            byte_q.push_back(temp_hdr_amd[(8*i-1)-:8]);
        end
    end

    if(rlc_pdu_type == amd_pdu_sn12_so16) begin
        temp_hdr_amd[39:8] = {d_c, p, si, sn[11:0], so};
        rlc_hdr_l = 4;
        for (int i=5; i>1; i--) begin
            byte_q.push_back(temp_hdr_amd[(8*i-1)-:8]);
        end
    end

    if(rlc_pdu_type == amd_pdu_final) begin
        temp_hdr_amd[39:0] = {d_c, p, si, {2{r}}, sn, so};
        rlc_hdr_l = 5;
        for (int i=5; i>0; i--) begin
            byte_q.push_back(temp_hdr_amd[(8*i-1)-:8]);
        end
    end
    //---------------am
    if(rlc_pdu_type inside status_pdu) begin
        temp_hdr_amd[39:32] = {d_c, cpt, 4'b0000};
        rlc_hdr_l = 1;
        byte_q.push_back(temp_hdr_amd[39:32]);
    end
endfunction : pack_hdr


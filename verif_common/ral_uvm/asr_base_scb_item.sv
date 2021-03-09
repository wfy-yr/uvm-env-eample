class asr_base_scb_item extends uvm_sequence_item;
    typedef enum {WRITE, READ} rw_type_e;
    int   stream_id;

    rw_type_e  rw_type;
    bit [63:0] addr;
    bit [31:0] data;
    logic [31:0] sideband[string];

    static bit rw_on = 1;
    static bit addr_on = 1;
    static bit data_on = 1;
    static bit addr_on = 1;
    static bit sideband_on = 1;

    `uvm_object_utils_begin(asr_base_scb_item)
        `uvm_field_int(stream_id, UVM_ALL_ON|UVM_NOCOMPARE)
        if(rw_on) `uvm_field_enum(rw_type_e, rw_type, UVM_ALL_ON)
        if(addr_on) `uvm_field_int(addr, UVM_ALL_ON)
        if(data_on) `uvm_field_int(data, UVM_ALL_ON)
        if(sideband_on) `uvm_field_aa_int_string(sideband, UVM_ALL_ON)
    `uvm_object_utils_end

    function new (string name = "asr_base_scb_item");
        super.new(name);
    endfunction : new

    static function disable_rw ();
        rw_on=0;
    endfunction : disable_rw

    static function disable_addr ();
        addr_on=0;
    endfunction : disable_addr

    static function disable_data ();
        data_on=0;
    endfunction : disable_data

    static function disable_sideband ();
        sideband_on=0;
    endfunction : disable_sideband
endclass : asr_base_scb_item

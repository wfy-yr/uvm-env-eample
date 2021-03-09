class asr_base_scb_comparer extends uvm_comparer;
    static asr_base_scb_comparer me;
    string err_arg[$];
    string err_arr_str;

    extern function new();
    extern static function asr_base_scb_comparer get();
    extern virtual function void set_err_arg(string name);
    extern virtual function bit compare_field(string name,
                                              uvm_bitstream_t lhs,
                                              uvm_bitstream_t rhs,
                                              int size,
                                              uvm_radix_enum radix=UVM_NORADIX);
    extern virtual function bit compare_field_int(string name,
                                                  logic[63:0] lhs,
                                                  logic[63:0] rhs,
                                                  int size,
                                                  uvm_radix_enum radix=UVM_NORADIX);
    extern virtual function bit compare_field_real(string name,
                                                   real lhs,
                                                   real rhs);
    extern virtual function bit compare_object(string name,
                                               uvm_object lhs,
                                               uvm_object rhs);
    extern virtual function bit compare_string(string name,
                                               string lhs,
                                               string rhs);
endclass

function asr_base_scb_comparer::new();
    super.new();
    show_max=100;
endfunction

function asr_base_scb_comparer asr_base_scb_comparer::get();
    if(me==null) me=new();
    return me;
endfunction

function void asr_base_scb_comparer::set_err_arg(string name);
    if(name=="") begin
        string str=uvm_object::__m_uvm_status_container.scope.get_arg();
        string s;
        foreach(str[i]) begin
            if(str[i]=="["||i==str.len-1)begin
                if(i==str.len-1) s={s,str[i]};
                if(str[i]=="[" & err_arr_str!=s) err_arg.push_back(s);
                if(i==str.len-1) err_arg.push_back(s);
                if(str[i] == "[") begin
                    err_arr_str=s;
                    s=str[i];
                end
            end else begin
                s={s,str[i]};
            end
        end
    end else begin
        err_arg.push_back(name);
    end
endfunction

function bit asr_base_scb_comparer::compare_field(string name,
                           uvm_bitstream_t lhs,
                           uvm_bitstream_t rhs,
                           int size,
                           uvm_radix_enum radix=UVM_NORADIX);
    uvm_bitstream_t mask;

    if(size <= 64) return compare_field_int(name, lhs, rhs, size, radix);
    mask = -1;
    mask >>= (UVM_STREAMBITS-size);
    if((lhs & mask) !== (rhs & mask)) set_err_arg(name);
    return super.compare_field(name, lhs, rhs, size, radix);
endfunction
function bit asr_base_scb_comparer::compare_field_int(string name,
                               logic[63:0] lhs,
                               logic[63:0] rhs,
                               int size,
                               uvm_radix_enum radix=UVM_NORADIX);
    logic [63:0]  mask;

    mask = -1;
    mask >>= (64-size);
    if((lhs & mask) !== (rhs & mask)) set_err_arg(name);
    return super.compare_field_int(name, lhs, rhs, size, radix);
endfunction
function bit asr_base_scb_comparer::compare_field_real(string name,
                                real lhs,
                                real rhs);
    if(lhs != rhs) set_err_arg(name);
    return super.compare_field_real(name, lhs, rhs);
endfunction
function bit asr_base_scb_comparer::compare_object(string name,
                            uvm_object lhs,
                            uvm_object rhs);
    if(policy == UVM_REFERENCE && lhs != rhs) set_err_arg(name);
    if(lhs == null || rhs == null) set_err_arg(name);
    return super.compare_object(name, lhs, rhs);
endfunction
function bit asr_base_scb_comparer::compare_string(string name,
                            string lhs,
                            string rhs);
    if(lhs != rhs) set_err_arg(name);
    return super.compare_string(name, lhs, rhs);
endfunction

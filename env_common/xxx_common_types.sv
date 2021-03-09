typedef enum { 
    XXX_STREAM_NONE = 0, 
    XXX_VAR = 1000, 
    XXX_VAR_END = 2000 
} XXX_SCB_STREAM_ID_T;

//basic SCB item 
class xxx_base_trans extends uvm_sequence_item; 
    XXX_SCB_STREAM_ID_T stream_id; 
    `uvm_object_utils_begin(xxx_base_trans) 
        `uvm_field_enum(XXX_SCB_STREAM_ID_T, stream_id, UVM_ALL_ON | UVM_NOCOMPARE | UVM_NOPACK) 
    `uvm_object_utils_end 
    function new(string name="xxx_base_trans"); 
        super.new(name); 
    endfunction : new 
endclass : xxx_base_trans

class xxx_fifo_trans extends xxx_base_trans; 
    rand int delay; 
    `uvm_object_utils_begin(xxx_fifo_trans) 
        `uvm_field_int(delay, UVM_ALL_ON | UVM_NOCOMPARE | UVM_NOPACK) 
    `uvm_object_utils_end 
    function new(string name="xxx_fifo_trans"); 
        super.new(name); 
    endfunction : new
    constraint delay_cons {delay inside {[1:10]};}
endclass : xxx_fifo_trans

class default_packer_t extends uvm_packer; 
    function new(); 
        super.new(); 
        super.big_endian = 0; 
    endfunction : new 
endclass : default_packer_t

static default_packer_t default_packer = new;

task traverse_xxx_stream_name(output int unsigned stream_id[$], output string name[$]); 
    XXX_SCB_STREAM_ID_T id = id.first();
    do begin
        stream_id.push_back(id);
        id = id.next();
    end while(id != id.first());

    for(int unsigned ii=XXX_VAR; ii<=XXX_VAR_END; ii++) begin
        stream_id.push_back(ii);
    end
    stream_id = stream_id.unique();

    foreach(stream_id[ii]) begin
        name.push_back(get_xxx_stream_name(stream_id[ii]));
    end

endtask: traverse_xxx_stream_name

function string get_xxx_stream_name(XXX_SCB_STREAM_ID_T stream_id); 
    if(stream_id >= XXX_VAR && stream_id <= XXX_VAR_END) begin 
        return ($sformatf("XXX_VAR%0d", stream_id-XXX_VAR)); 
    end else begin 
        return stream_id.name(); 
    end 
endfunction : get_xxx_stream_name

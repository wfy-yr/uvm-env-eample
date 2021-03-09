//User need to update insert_transform & expect_transform functions to: 
//1.Convert insert type -> compare type 
//2.Convert expect type -> compare type 
//Comparing is done by base_scoreboard

class xxx_scb extends asr_base_scoreboard #(xxx_fifo_trans,xxx_fifo_trans,xxx_fifo_trans);

typedef xxx_fifo_trans compare_type;
typedef xxx_fifo_trans insert_type;
typedef xxx_fifo_trans expect_type;

`uvm_component_utils(xxx_scb)

xxx_env_cfg    m_xxx_env_cfg;

extern function new(string name="xxx_scb", uvm_component parent=null);
extern virtual function void build_phase(uvm_phase phase);
extern virtual function void insert_transform(input  insert_type  insert_pkt,
                                              output compare_type out_pkts[],
                                              ref    bit           drop_bit,
                                              ref    int           stream_id);
extern virtual function void expect_transform(input  expect_type  expect_pkt,
                                              output compare_type out_pkts[],
                                              ref    bit           drop_bit,
                                              ref    int           stream_id);

endclass : xxx_scb

function xxx_scb::new(string name="xxx_scb", uvm_component parent=null); 
    super.new(name, parent); 
endfunction : new

function void xxx_scb::build_phase(uvm_phase phase); super.build_phase(phase); 
//virtual sequencer connect 
    if(!uvm_config_db#(xxx_env_cfg)::get(this, "", "m_xxx_env_cfg", m_xxx_env_cfg)) begin 
        `uvm_info(get_name(), {"Can't get m_xxx_env_cfg handle"}, UVM_MEDIUM) 
    end 
endfunction : build_phase

function void xxx_scb::insert_transform(input insert_type insert_pkt, output compare_type out_pkts[], ref bit drop_bit, ref int stream_id); 
//Usage: 
//1.Convert insert_type to compare_type when insert_type and compare_type are different 
//2.Set drop_bit=1 when you wan't to insert the pkt into scb 
//3.Set streat_id when have multi-stream
    out_pkts=new[1];
    assert($cast(out_pkts[0] ,insert_pkt.clone()));
    stream_id = insert_pkt.stream_id + insert_pkt.ch_id;
// insert_type = compare_type, by default direct mapping :

endfunction : insert_transform

function void xxx_scb::expect_transform(input expect_type expect_pkt, output compare_type out_pkts[], ref bit drop_bit, ref int stream_id); 
//Usage:
//1.Convert expect_type to compare_type when expect_type and compare_type are different
//2.Set drop_bit=1 when you wan't to expect the pkt into scb 
//3.Set streat_id when have multi-stream
    out_pkts=new[1];
    assert($cast(out_pkts[0] ,expect_pkt.clone()));
    stream_id = expect_pkt.stream_id + expect_pkt.ch_id;
// expect_type = compare_type, by default direct mapping :

endfunction : expect_transform

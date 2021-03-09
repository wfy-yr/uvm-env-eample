// =========================================================================== //
// Author       : fengyang.wu - ASR
// Last modified: 2020-07-10 14:19
// Filename     : asr_ral_base_seq.sv
// Description  : 
// =========================================================================== //
// variables need to be configured in base_test or top vseq :
// 1.reg model
// 2.address map name , default = "default" --- means default map of root reg blk
// 3.blk_hier string , default =  ""

// configure method 1: via m_sequencer : only applied to top ral vseq for current env, for sub ral vseq, pls use method 2 in the top ral vseq
// uvm_config_db#(uvm_reg_block)::set(vseqr, "", "reg_model", reg_model);
// uvm_config_db#(string)::set(vseqr, "", "root_map_name", "default_map_name");
// uvm_config_db#(string)::set(vseqr, "", "blk_hier", "blk_hier");

//configure method 2: via task call
//to reuse uart ip cfg seq in ap subsystem:
//rx_mac_cfg_seq.set_model(.reg_model(ap_reg_model), .hier("uart_rf"), .map_name("ap")); or
//rx_mac_cfg_seq.set_model(.reg_model(ap_reg_model.uart_rf), .hier(""), .map_name("ap"));

//eg: (ap subsys test):
//in ap_test.sv:
//              uvm_config_db#(uvm_reg_block)::set(vseqr, "", "reg_model", ap_model);
//              uvm_config_db#(string)::set(vseqr, "", "root_map_name", ap_model);
//              uvm_config_db#(string)::set(vseqr, "", "blk_hier", blk_hier);
//          
//in ap_cfg_vseq (top ral vseq, will get ap_model as reg_model):
//              dma_cfg_seq.set_model(.reg_model(this.reg_model), .hier("dma_blk"), .map_name("ap_map"));
//              dma_cfg_seq.start(m_sequencer);
//
//in reused dma cfg seq
//             write_reg_by_name("CHN_SEL", 'hff)     // with default map "ap_map"
//             write_reg_by_name("CHN_SEL", 'hff, , "aon_map")     // with map "aon_map"
//             write_reg_by_offset('h10, 'hff, , "aon_map")     // with offset inside map "aon_map"

`ifndef ASR_RAL_BASE_SEQ_SV
`define ASR_RAL_BASE_SEQ_SV

class asr_ral_base_seq extends uvm_sequence;
    uvm_status_e status;

    protected uvm_reg_block    reg_model[string];
    protected string           blk_hier = "";
    protected uvm_reg_addr_t   blk_ofst[string][string];
    protected string           root_map_name[string];
    
    protected uvm_reg_map maps[string][string];
    protected uvm_reg_block root_model[string];
    protected uvm_reg_block leaf_model[string];
    protected string model_name;

    uvm_reg_data_t               reg_data_aa[string];

    //!!!! don't define p_sequencer, otherwise cannot reuse
    `uvm_object_utils(asr_ral_base_seq)


    extern function new(string name="asr_ral_base_seq");

    extern virtual function void set_model(uvm_reg_block reg_model, string hier="", string root_map_name = "default_map", string leaf_model_name = "");
    extern virtual function void proc_model(uvm_reg_block reg_model, string hier, string root_map_name, string leaf_model_name = "");
    extern virtual function void find_root_blk(uvm_reg_block reg_model, output uvm_reg_block root_model, string hier);
    extern virtual function void get_blk_offset(uvm_reg_block leaf_model, uvm_reg_block root_model);
    extern virtual task write_reg_by_name(input string reg_name, input uvm_reg_data_t wdata, string map_name = "", string model_name = "", 
                                          uvm_path_e path = UVM_FRONTDOOR, uvm_object extension = null, bit check_rsp = 0, string cur_file = "", int cur_line=0);
    extern virtual task read_reg_by_name(input string reg_name, input uvm_reg_data_t rdata, string map_name = "", string model_name = "", 
                                         uvm_path_e path = UVM_FRONTDOOR, uvm_object extension = null, bit check_rsp = 0, string cur_file = "", int cur_line=0);
    extern virtual task write_field_by_name(input string field_name, input string reg_name, input uvm_reg_data_t wdata, string map_name = "", string model_name = "", 
                                            uvm_path_e path = UVM_FRONTDOOR, uvm_object extension = null, bit check_rsp = 0, string cur_file = "", int cur_line=0);
    extern virtual task read_field_by_name(input string field_name, input string reg_name, input uvm_reg_data_t rdata, string map_name = "", string model_name = "", 
                                           uvm_path_e path = UVM_FRONTDOOR, uvm_object extension = null, bit check_rsp = 0, string cur_file = "", int cur_line=0);
    extern virtual task get_field_by_name(input string field_name, input string reg_name, output uvm_reg_data_t rdata, input string model_name = "", 
                                          string cur_file = "", int cur_line=0);
    extern protected virtual function uvm_reg_field get_field_obj_by_name(input string field_name, input string reg_name, input string model_name = "", string cur_file = "", int cur_line=0);
    extern virtual task reg_write(uvm_reg cur_reg, input uvm_reg_data_t wdata, uvm_path_e path = UVM_FRONTDOOR,
                                  uvm_reg_map map = null, uvm_object extension = null, bit check_rsp = 0, string cur_file = "", int cur_line=0);
    extern virtual task reg_read(uvm_reg cur_reg, output uvm_reg_data_t rdata, uvm_path_e path = UVM_FRONTDOOR,
                                 uvm_reg_map map = null, uvm_object extension = null, bit check_rsp = 0, string cur_file = "", int cur_line=0);
    extern protected virtual function uvm_reg_map get_map_by_name(ref string model_name, ref string map_name);
    extern protected virtual function uvm_reg find_reg_by_name(ref string model_name, string base_name);
    extern protected virtual function uvm_reg_block get_model_by_name(ref string model_name);
    extern protected virtual function void get_maps(ref string model_name, output uvm_reg_map maps[$]);
    extern virtual task write_vmem_bytes(input uvm_mem mem_inst, uvm_reg_addr_t byte_offset, bit [7:0] wbytes[],
                                             uvm_reg_map map, uvm_path_e path = UVM_FRONTDOOR, uvm_object extension = null,
                                             bit check_rsp = 0, string cur_file="", int cur_line=0);
    extern virtual task read_vmem_bytes(input uvm_mem mem_inst, uvm_reg_addr_t byte_offset, bit [7:0] rbytes[],
                                            uvm_reg_map map, uvm_path_e path = UVM_FRONTDOOR, uvm_object extension = null,
                                            bit check_rsp = 0, string cur_file="", int cur_line=0);
endclass: asr_ral_base_seq

function asr_ral_base_seq::new(string name="asr_ral_base_seq");
   super.new(name);
endfunction : new

//root.A.B.C.cur_blk
//task to use root as reg_model here, need to provide hier and offset of cur_blk
//user must set leaf_map_name to auto gen blk_offset
function void asr_ral_base_seq::set_model(uvm_reg_block reg_model, string hier="", string root_map_name = "default_map", string leaf_model_name = "");
    proc_model(reg_model, hier, root_map_name, leaf_model_name);
endfunction : set_model

function void asr_ral_base_seq::proc_model(uvm_reg_block reg_model, string hier, string root_map_name, string leaf_model_name = "");
    string tmp_hier;
    string leaf_name;
    uvm_reg_block leaf_model, root_model;

    if(hier == "") leaf_model = reg_model;
    else begin
        leaf_model = reg_model.find_block(hier, reg_model);
        `uvm_info("asr_ral_base_seq_DEBUG_MODEL", $sformatf("reg_model:%s, hier:%s, leaf:%s", reg_model.get_full_name(), hier, leaf_model.get_full_name()), UVM_FULL)
    end
    if(leaf_model_name != "") leaf_name = leaf_model_name;
    else leaf_name = leaf_model.get_name();

    this.reg_model[leaf_name] = reg_model;
    this.root_map_name[leaf_name] = root_map_name;
    this.leaf_model[leaf_name] = leaf_model;
    this.model_name = leaf_name;

    find_root_blk(leaf_model, root_model, tmp_hier);
    `uvm_info("asr_ral_base_seq_DEBUG_MODEL", $sformatf("reg_model:%s, hier:%s, root_model:%s, leaf_model:%s", reg_model.get_full_name(), hier, root_model.get_full_name(), leaf_model.get_full_name()), UVM_FULL)
    this.root_model[leaf_name] = root_model;
    get_blk_offset(leaf_model, root_model);
endfunction : proc_model

function void asr_ral_base_seq::find_root_blk(uvm_reg_block reg_model, output uvm_reg_block root_model, string hier);
    uvm_reg_block parent;
    uvm_reg_block blk;

    hier = "";
    blk = reg_model;
    parent = reg_model.get_parent();
    while (parent != null) begin
        blk = parent;
        hier = {parent.get_name(), ".", hier};
        parent = blk.get_parent();
    end
    root_model = blk;
endfunction : find_root_blk

function void asr_ral_base_seq::get_blk_offset(uvm_reg_block leaf_model, uvm_reg_block root_model);
    uvm_reg_map blk_map, root_map;
    uvm_reg_map blk_maps[$];
    uvm_reg_map root_maps[$];
    string leaf_name = leaf_model.get_name();

    //get all blk map
    leaf_model.get_maps(blk_maps);
    root_model.get_maps(root_maps);

    //get root map of blk map -> derive offset
    foreach(blk_maps[ii]) begin
        root_map = blk_maps[ii].get_root_map();
        if(root_map inside {root_maps} == 0) continue;
        this.blk_ofst[leaf_name][root_map.get_name()] = blk_maps[ii].get_base_addr(UVM_HIER);
        this.maps[leaf_name][this.root_map_name[leaf_name]] = blk_maps[ii];
        `uvm_info("asr_ral_base_seq_DEBUG_MODEL", $sformatf("blk_map:%s, root_map:%s, offset[%s]:%h", blk_maps[ii].get_full_name(), root_map.get_full_name(), leaf_name, this.blk_ofst[leaf_name][root_map.get_name()]), UVM_FULL)
    end

endfunction : get_blk_offset

task asr_ral_base_seq::write_reg_by_name(input string reg_name, input uvm_reg_data_t wdata, string map_name = "", string model_name = "", 
                                         uvm_path_e path = UVM_FRONTDOOR, uvm_object extension = null, bit check_rsp = 0, string cur_file = "", int cur_line=0);
    uvm_reg my_reg;
    uvm_reg_map cur_map;
    string tmp_model_name = model_name;
    uvm_sequencer_base  seqr;
    //check_reg_model();
    cur_map = get_map_by_name(tmp_model_name, map_name);
    my_reg  = find_reg_by_name(model_name, reg_name);

    if(cur_map == null) begin
        `uvm_error("WRITE_REG_BY_NAME", $sformatf("[%s Map %s.%s not found]", get_full_name(), model_name, map_name))
        return;
    end

    if(my_reg == null) begin
        `uvm_error("WRITE_REG_BY_NAME", $sformatf("[%s Register %s.%s not found]", get_full_name(), model_name, reg_name))
        return;
    end
    seqr = cur_map.get_sequencer();
    if(seqr == null) begin
        `uvm_error("WRITE_REG_BY_NAME", $sformatf("[%s Register seqr not found]", get_full_name()))
        return;
    end

    `uvm_info("WRITE_REG_BY_NAME", $sformatf("[%s  test   %s.%s = 0x%8h in %s seqr=%s]", get_full_name(), model_name, reg_name, wdata, cur_map.get_full_name(), seqr.get_full_name()), UVM_FULL)
    reg_write(my_reg, wdata, path, cur_map, extension, check_rsp, cur_file, cur_line);
    `uvm_info("WRITE_REG_BY_NAME", $sformatf("[%s     %s.%s = 0x%8h in %s]", get_full_name(), model_name, reg_name, wdata, cur_map.get_full_name()), UVM_FULL)
endtask : write_reg_by_name

task asr_ral_base_seq::read_reg_by_name(input string reg_name, input uvm_reg_data_t rdata, string map_name = "", string model_name = "", 
                                         uvm_path_e path = UVM_FRONTDOOR, uvm_object extension = null, bit check_rsp = 0, string cur_file = "", int cur_line=0);
    uvm_reg my_reg;
    uvm_reg_map cur_map;
    string tmp_model_name = model_name;
    //check_reg_model();
    cur_map = get_map_by_name(tmp_model_name, map_name);
    my_reg  = find_reg_by_name(model_name, reg_name);

    if(cur_map == null) begin
        `uvm_error("READ_REG_BY_NAME", $sformatf("[%s Map %s.%s not found]", get_full_name(), model_name, map_name))
        return;
    end

    if(my_reg == null) begin
        `uvm_error("READ_REG_BY_NAME", $sformatf("[%s Register %s.%s not found]", get_full_name(), model_name, reg_name))
        return;
    end

    reg_read(my_reg, rdata, path, cur_map, extension, check_rsp, cur_file, cur_line);
    `uvm_info("READ_REG_BY_NAME", $sformatf("[%s     %s.%s = 0x%8h in %s]", get_full_name(), model_name, reg_name, rdata, map_name), UVM_FULL)
endtask : read_reg_by_name

task asr_ral_base_seq::write_field_by_name(input string field_name, input string reg_name, input uvm_reg_data_t wdata, string map_name = "", string model_name = "", 
                                         uvm_path_e path = UVM_FRONTDOOR, uvm_object extension = null, bit check_rsp = 0, string cur_file = "", int cur_line=0);
    uvm_reg my_reg,my_reg_l,my_reg_h;
    uvm_reg_data_t reg_data,reg_data_l,reg_data_h;
    uvm_reg_field my_field;
    uvm_reg_map cur_map;
    string tmp_model_name = model_name;
    //check_reg_model();

    if(reg_name != "") begin

        cur_map = get_map_by_name(tmp_model_name, map_name);
        my_reg  = find_reg_by_name(model_name, reg_name);
        
        if(cur_map == null) begin
            `uvm_error("WRITE_FIELD_BY_NAME", $sformatf("[%s Map %s.%s not found]", get_full_name(), model_name, map_name))
            return;
        end

        if(my_reg == null) begin
            `uvm_error("WRITE_FIELD_BY_NAME", $sformatf("[%s Register %s.%s not found]", get_full_name(), model_name, reg_name))
            return;
        end

        my_field = my_reg.get_field_by_name(field_name);

        if(my_field == null) begin
            `uvm_error("WRITE_FIELD_BY_NAME", $sformatf("[%s Field %s in Register %s.%s not found]", get_full_name(), field_name, model_name, reg_name))
            return;
        end
    end
    else begin
        my_field = get_field_obj_by_name(field_name, reg_name, model_name, cur_file, cur_line);
        my_reg = my_field.get_parent();
    end
    //------------------32 bit reg--------------------------//
    //void'(my_field.predict(wdata));
    //reg_write(my_reg, my_reg.get(), path, cur_map, extension, check_rsp, cur_file, cur_line);
    //------------------for 64 bit reg by fengyangwu modify------------------//
    cur_map = get_map_by_name(tmp_model_name, map_name);
    `uvm_info("WRITE_FIELD_BY_NAME", $sformatf("[%s Map %s.%s]", get_full_name(), model_name, map_name), UVM_FULL)
    reg_data=my_reg.get();
    reg_data_l=reg_data[31:0];
    reg_data_h=reg_data[63:32];
    void'(my_field.predict(wdata));
    reg_data=my_reg.get();
    `uvm_info("WRITE_FIELD_BY_NAME", $sformatf("[%s write_data=0x%0h reg_data_h=0x%0h reg_data_l=0x%0h]", get_full_name(), reg_data, reg_data_h, reg_data_l), UVM_FULL)
    if((reg_data[31:0] == reg_data_l) && (reg_data[63:32] != reg_data_h)) begin
        reg_write(my_reg, {reg_data[63:32],32'h12345678}, path, cur_map, extension, check_rsp, cur_file, cur_line);
    end
    else if((reg_data[31:0] != reg_data_l) && (reg_data[63:32] == reg_data_h)) begin
        reg_write(my_reg, {32'h12345678,reg_data[31:0]}, path, cur_map, extension, check_rsp, cur_file, cur_line);
    end
    else begin
        reg_write(my_reg, reg_data, path, cur_map, extension, check_rsp, cur_file, cur_line);
    end

    `uvm_info("WRITE_FIELD_BY_NAME", $sformatf("[%s     %s.%s::%s = 0x%8h]", get_full_name(), model_name, reg_name, field_name, wdata), UVM_FULL)
endtask : write_field_by_name

task asr_ral_base_seq::read_field_by_name(input string field_name, input string reg_name, input uvm_reg_data_t rdata, string map_name = "", string model_name = "", 
                                         uvm_path_e path = UVM_FRONTDOOR, uvm_object extension = null, bit check_rsp = 0, string cur_file = "", int cur_line=0);
    uvm_reg my_reg;
    uvm_reg_field my_field;
    uvm_reg_map cur_map;
    string tmp_model_name = model_name;
    //check_reg_model();

    if(reg_name != "") begin

        cur_map = get_map_by_name(tmp_model_name, map_name);
        my_reg  = find_reg_by_name(model_name, reg_name);
        
        if(cur_map == null) begin
            `uvm_error("READ_FIELD_BY_NAME", $sformatf("[%s Map %s.%s not found]", get_full_name(), model_name, map_name))
            return;
        end

        if(my_reg == null) begin
            `uvm_error("READ_FIELD_BY_NAME", $sformatf("[%s Register %s.%s not found]", get_full_name(), model_name, reg_name))
            return;
        end

        my_field = my_reg.get_field_by_name(field_name);

        if(my_field == null) begin
            `uvm_error("READ_FIELD_BY_NAME", $sformatf("[%s Field %s in Register %s.%s not found]", get_full_name(), field_name, model_name, reg_name))
            return;
        end
    end
    else begin
        my_field = get_field_obj_by_name(field_name, reg_name, model_name, cur_file, cur_line);
        my_reg = my_field.get_parent();
    end
    void'(my_field.predict(rdata));
    reg_read(my_reg, rdata, path, cur_map, extension, check_rsp, cur_file, cur_line);
    `uvm_info("READ_FIELD_BY_NAME", $sformatf("[%s     %s.%s::%s = 0x%8h]", get_full_name(), model_name, reg_name, field_name, rdata), UVM_FULL)
endtask : read_field_by_name

task asr_ral_base_seq::get_field_by_name(input string field_name, input string reg_name, output uvm_reg_data_t rdata, input string model_name = "", 
                                        string cur_file = "", int cur_line=0);
    uvm_reg my_reg;
    uvm_reg_field my_field;

    my_field = get_field_obj_by_name(field_name, reg_name, model_name, cur_file, cur_line);
    rdata = my_field.get();
    `uvm_info("GET_FIELD_BY_NAME", $sformatf("[%s     %s.%s::%s = 0x%8h ]", get_full_name(), model_name, reg_name, field_name, rdata), UVM_FULL)
endtask : get_field_by_name

function uvm_reg_field asr_ral_base_seq::get_field_obj_by_name(input string field_name, input string reg_name, input string model_name = "", string cur_file = "", int cur_line=0);
    uvm_reg my_reg;
    uvm_reg_field my_field;
    uvm_reg_block my_blk;

    if(reg_name != "") begin

        my_reg  = find_reg_by_name(model_name, reg_name);
        
        if(my_reg == null) begin
            `uvm_error("WRITE_FIELD_OBJ_BY_NAME", $sformatf("[%s Register %s.%s not found]", get_full_name(), model_name, reg_name))
            return null;
        end

        my_field = my_reg.get_field_by_name(field_name);

    end
    else begin
        my_blk = get_model_by_name(model_name);
        
        if(my_blk == null) begin
            `uvm_error("WRITE_FIELD_OBJ_BY_NAME", $sformatf("[%s Model %s not found]", get_full_name(), model_name))
            return null;
        end
        my_field = my_blk.get_field_by_name(field_name);
    end

    if(my_field == null) begin
        `uvm_error("WRITE_FIELD_OBJ_BY_NAME", $sformatf("[%s Field %s in Register %s.%s not found]", get_full_name(), field_name, model_name, reg_name))
        return null;
    end

    return my_field;
endfunction : get_field_obj_by_name

task asr_ral_base_seq::reg_write(uvm_reg cur_reg, input uvm_reg_data_t wdata, uvm_path_e path = UVM_FRONTDOOR,
                                 uvm_reg_map map = null, uvm_object extension = null, bit check_rsp = 0, string cur_file = "", int cur_line=0);
    uvm_status_e my_status;

    cur_reg.write(my_status, wdata, path, map, , ,extension, cur_file, cur_line);

    if(check_rsp && my_status != UVM_IS_OK) begin
        `uvm_error("WRITE_REG", $sformatf("[%s %s = 0x%8h via map %s, get resp %s !!!!]", get_full_name(), cur_reg.get_full_name(), wdata, map.get_name(), my_status.name()))
    end
    this.status = my_status;
endtask : reg_write

task asr_ral_base_seq::reg_read(uvm_reg cur_reg, output uvm_reg_data_t rdata, uvm_path_e path = UVM_FRONTDOOR,
                                 uvm_reg_map map = null, uvm_object extension = null, bit check_rsp = 0, string cur_file = "", int cur_line=0);
    uvm_status_e my_status;

    cur_reg.read(my_status, rdata, path, map, , ,extension, cur_file, cur_line);

    if(check_rsp && my_status != UVM_IS_OK) begin
        `uvm_error("READ_REG", $sformatf("[%s %s = 0x%8h via map %s, get resp %s !!!!]", get_full_name(), cur_reg.get_full_name(), rdata, map.get_name(), my_status.name()))
    end
    this.status = my_status;
endtask : reg_read


function uvm_reg_map asr_ral_base_seq::get_map_by_name(ref string model_name, ref string map_name);
    uvm_reg_map reg_map[$];
    uvm_reg_block parent;

    if(model_name == "") model_name = this.model_name;

    if(!this.root_map_name.exists(model_name)) begin
        model_name = this.model_name;
    end

    if(map_name == "") map_name = this.root_map_name[model_name];
    if(!root_model.exists(model_name)) begin
        `uvm_fatal(get_full_name(), $sformatf("[cannot find model %s]", model_name))
    end

    if(this.maps[model_name].exists(map_name)) begin
        return this.maps[model_name][map_name];
    end
    return null;
endfunction : get_map_by_name

function uvm_reg asr_ral_base_seq::find_reg_by_name(ref string model_name, string base_name);
    string hier_names[$];
    string reg_name;
    uvm_reg_block cur_blk;
    if(model_name == "") model_name = this.model_name;
    cur_blk = leaf_model[model_name];

    if(cur_blk == null) begin
        base_name = {model_name, ".", base_name};
        model_name = this.model_name;
        cur_blk = leaf_model[model_name];
    end

    uvm_split_string(base_name, ".", hier_names);
    reg_name = hier_names.pop_back();

    foreach(hier_names[ii]) begin
        string blk_name = hier_names[ii];
        cur_blk = cur_blk.get_block_by_name(blk_name);
        if(cur_blk == null) begin
            `uvm_fatal(get_full_name(), $sformatf("[cannot find hier name %s in leaf_model %s]", base_name, leaf_model[model_name].get_full_name()))
        end
    end
    return cur_blk.get_reg_by_name(reg_name);
endfunction : find_reg_by_name

function uvm_reg_block asr_ral_base_seq::get_model_by_name(ref string model_name);
    uvm_reg_block cur_blk;
    if(model_name == "") model_name = this.model_name;
    return leaf_model[model_name];
endfunction : get_model_by_name

function void asr_ral_base_seq::get_maps(ref string model_name, output uvm_reg_map maps[$]);
    uvm_reg_block parent;

    if(model_name == "") model_name = this.model_name;
    if(!root_model.exists(model_name))  `uvm_fatal(get_full_name(), $sformatf("cannot find model %s", model_name))
    foreach(this.maps[model_name][map_name]) maps.push_back(this.maps[model_name][map_name]);
endfunction : get_maps

task asr_ral_base_seq::write_vmem_bytes(input uvm_mem mem_inst, uvm_reg_addr_t byte_offset, bit [7:0] wbytes[],
                          uvm_reg_map map, uvm_path_e path = UVM_FRONTDOOR, uvm_object extension = null,
                          bit check_rsp = 0, string cur_file="", int cur_line=0);
    uvm_reg_data_t mem_entry[];
    int n_bytes;
    uvm_reg_map cur_map;
    uvm_status_e my_status;
    longint index;


    if(mem_inst == null) begin
        `uvm_error("VMEM_WRITE", $sformatf("Null mem_inst"))
        return;
    end
    cur_map = map;
    n_bytes = mem_inst.get_n_bytes();
    if((wbytes.size() % n_bytes) != 0) begin
        `uvm_error("VMEM_WRITE", $sformatf("mem %s entry bytes=%0d, data entry size=%0d, is not multiple of entry size", mem_inst.get_full_name(), n_bytes, wbytes.size()))
    end
    if((byte_offset % n_bytes) != 0) begin
        `uvm_error("VMEM_WRITE", $sformatf("mem %s entry bytes=%0d, access_start='h%0x, is not multiple of entry size", mem_inst.get_full_name(), n_bytes, byte_offset))
    end
    index = byte_offset/n_bytes;
    mem_entry = new[wbytes.size()/n_bytes];
    
    foreach(mem_entry[ii]) begin
        uvm_reg_data_t temp_data = 0;
        for(int jj=0; jj < n_bytes; jj++) begin
            temp_data[(n_bytes-1)*8+:8] = wbytes[n_bytes*ii + jj];
            if(jj != n_bytes-1) temp_data >>=8;
        end
        mem_entry[ii] = temp_data;
    end
    mem_inst.burst_write(my_status, index, mem_entry, path, cur_map, , , extension, cur_file, cur_line);

    if(check_rsp && my_status != UVM_IS_OK) begin
        `uvm_error("VMEM_WRITE", $sformatf("[%s[%0d] number=%0d first=0x%8h via map %s, get resp %s !!!!]", mem_inst.get_full_name(), index, mem_entry.size(), mem_entry[0], cur_map.get_name(), my_status.name()))
    end
    `uvm_info("VMEM_WRITE", $sformatf("[entry %s[%0d] number=%0d first=0x%8h via map %s, get resp %s ", mem_inst.get_full_name(), index, mem_entry.size(), mem_entry[0], cur_map.get_name(), my_status.name()), UVM_FULL)
    this.status = my_status;
endtask : write_vmem_bytes 

task asr_ral_base_seq::read_vmem_bytes(input uvm_mem mem_inst, uvm_reg_addr_t byte_offset, bit [7:0] rbytes[],
                          uvm_reg_map map, uvm_path_e path = UVM_FRONTDOOR, uvm_object extension = null,
                          bit check_rsp = 0, string cur_file="", int cur_line=0);
    uvm_reg_data_t mem_entry[];
    int n_bytes;
    uvm_reg_map cur_map;
    uvm_status_e my_status;
    longint index;


    if(mem_inst == null) begin
        `uvm_error("VMEM_READ", $sformatf("Null mem_inst"))
        return;
    end
    cur_map = map;
    n_bytes = mem_inst.get_n_bytes();
    if((rbytes.size() % n_bytes) != 0) begin
        `uvm_error("VMEM_READ", $sformatf("mem %s entry bytes=%0d, data entry size=%0d, is not multiple of entry size", mem_inst.get_full_name(), n_bytes, rbytes.size()))
    end
    if((byte_offset % n_bytes) != 0) begin
        `uvm_error("VMEM_READ", $sformatf("mem %s entry bytes=%0d, access_start='h%0x, is not multiple of entry size", mem_inst.get_full_name(), n_bytes, byte_offset))
    end
    index = byte_offset/n_bytes;
    mem_entry = new[rbytes.size()/n_bytes];
    
    mem_inst.burst_read(my_status, index, mem_entry, path, cur_map, , , extension, cur_file, cur_line);
    if(check_rsp && my_status != UVM_IS_OK) begin
        `uvm_error("VMEM_READ", $sformatf("[%s[%0d] number=%0d first=0x%8h via map %s, get resp %s !!!!]", mem_inst.get_full_name(), index, mem_entry.size(), mem_entry[0], cur_map.get_name(), my_status.name()))
    end
    `uvm_info("VMEM_READ", $sformatf("[entry %s[%0d] number=%0d first=0x%8h via map %s, get resp %s ", mem_inst.get_full_name(), index, mem_entry.size(), mem_entry[0], cur_map.get_name(), my_status.name()), UVM_FULL)

    foreach(mem_entry[ii]) begin
        uvm_reg_data_t temp_data = mem_entry[ii];
        for(int jj=0; jj < n_bytes; jj++) begin
            rbytes[n_bytes*ii + jj]     = temp_data[7:0];
            temp_data >>=8;
        end
    end

    this.status = my_status;
endtask : read_vmem_bytes 
`endif


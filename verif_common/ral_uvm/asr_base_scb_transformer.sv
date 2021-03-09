class asr_base_scb_transformer#(type T=int, type SCB_T=T) extends uvm_component;
    typedef asr_base_scb_transformer #(T, SCB_T) this_type;
    `uvm_component_param_utils(this_type)

    uvm_analysis_imp #(T, this_type) transform_export;
    uvm_analysis_port #(SCB_T)       scb_export;

    function new (string name = "asr_base_scb_transformer", uvm_component parent);
        super.new(name, parent);
        transform_export = new("transform_export", this);
        scb_export = new("scb_export", this);
    endfunction : new

    //transaction -> scb item
    extern virtual function void write(T t);
    extern virtual function void T2SCBT(T in_pkt, output SCB_T scb_item[]);
endclass: asr_base_scb_transformer

function void asr_base_scb_transformer::write(T t);
    SCB_T scb_item[];
    T2SCBT(t, scb_item);
    foreach(scb_item[i]) scb_export.write(scb_item[i]);
endfunction
function void asr_base_scb_transformer::T2SCBT(T in_pkt, output SCB_T scb_item[]);
    //TODO: Override this function to transform T type to SCB_T type for compare
    //      modify the codes below
    //scb_item=new[1];
    //scb_item[0]=new("scb_item");
    //if(!$cast(in_pkt, scb_item))
    `uvm_fatal(this.get_name(), $sformatf("Override this function to transform scb_item %0s to %0s", scb_item[0].get_type_name(), in_pkt.get_type_name()))
endfunction

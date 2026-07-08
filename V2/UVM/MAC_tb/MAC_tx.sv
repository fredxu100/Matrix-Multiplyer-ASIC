class MAC_tx extends uvm_sequence_item;
    `uvm_object_utils_begin(MAC_tx)
        `uvm_field_int(ain,         UVM_ALL_ON)
        `uvm_field_int(bin,         UVM_ALL_ON)
        `uvm_field_int(en,          UVM_ALL_ON)
        `uvm_field_int(rst,         UVM_ALL_ON)
        `uvm_field_int(aout,        UVM_ALL_ON)
        `uvm_field_int(bout,        UVM_ALL_ON)
        `uvm_field_int(accumulator, UVM_ALL_ON)
    `uvm_object_utils_end
    
    rand logic [7:0] ain, bin; 
    rand logic en, rst;
    logic [7:0] aout, bout;
    logic [24:0] accumulator;
    
    function new (string name = "transaction");
        super.new(name);
    endfunction

endclass
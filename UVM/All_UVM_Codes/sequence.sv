// Object class


class core_base_sequence extends uvm_sequence;
  `uvm_object_utils(core_base_sequence)
  
  core_sequence_item reset_pkt;
  
  //--------------------------------------------------------
  //Constructor
  //--------------------------------------------------------
  function new(string name= "core_base_sequence");
    super.new(name);
    `uvm_info("BASE_SEQ", "Inside Constructor!", UVM_HIGH)
  endfunction
  
  
  //--------------------------------------------------------
  //Body Task
  //--------------------------------------------------------
  task body();
    `uvm_info("BASE_SEQ", "Inside body task!", UVM_HIGH)
    
    reset_pkt = core_sequence_item::type_id::create("reset_pkt");
    start_item(reset_pkt);
    reset_pkt.randomize() with {rst==1;};
    finish_item(reset_pkt);
        
  endtask: body
  
  
endclass: core_base_sequence



class core_test_sequence extends core_base_sequence;
  `uvm_object_utils(core_test_sequence)
  
  core_sequence_item item;
  
  //--------------------------------------------------------
  //Constructor
  //--------------------------------------------------------
  function new(string name= "core_test_sequence");
    super.new(name);
    `uvm_info("TEST_SEQ", "Inside Constructor!", UVM_HIGH)
  endfunction
  
  
  //--------------------------------------------------------
  //Body Task
  //--------------------------------------------------------
  task body();
    `uvm_info("TEST_SEQ", "Inside body task!", UVM_HIGH)
    
    item = core_sequence_item::type_id::create("item");
    start_item(item);
    item.randomize() with {rst==0;};
    finish_item(item);
        
  endtask: body
  
  
endclass: core_test_sequence
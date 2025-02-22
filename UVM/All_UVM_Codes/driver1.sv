
class core_driver1 extends uvm_driver#(core_sequence_item);
  `uvm_component_utils(core_driver1)
  
  virtual core_interface vif;
  core_sequence_item item;
  
  
  //--------------------------------------------------------
  //Constructor
  //--------------------------------------------------------
  function new(string name = "core_driver1", uvm_component parent);
    super.new(name, parent);
    `uvm_info("DRIVER_CLASS", "Inside Constructor!", UVM_HIGH)
  endfunction: new
  
  
  //--------------------------------------------------------
  //Build Phase
  //--------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("DRIVER_CLASS", "Build Phase!", UVM_HIGH)
    
    if(!(uvm_config_db #(virtual core_interface)::get(this, "*", "vif", vif))) begin
      `uvm_error("DRIVER_CLASS", "Failed to get VIF from config DB!")
    end
    
  endfunction: build_phase
  
  
  //--------------------------------------------------------
  //Connect Phase
  //--------------------------------------------------------
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info("DRIVER_CLASS", "Connect Phase!", UVM_HIGH)
    
  endfunction: connect_phase
  
  
  //--------------------------------------------------------
  //Run Phase
  //--------------------------------------------------------
  task run_phase (uvm_phase phase);
    super.run_phase(phase);
    `uvm_info("DRIVER_CLASS", "Inside Run Phase!", UVM_HIGH)
    
    forever begin
      item = core_sequence_item::type_id::create("item"); 
      seq_item_port.get_next_item(item);
      drive(item);
      seq_item_port.item_done();
    end
    
  endtask: run_phase
  
  
  //--------------------------------------------------------
  //[Method] Drive
  //--------------------------------------------------------
  task drive(core_sequence_item item);
    @(posedge vif.clk);
    vif.rst <= item.rst;
    vif.mem_read_data <= item.mem_read_data;
    vif.mem_ready <= item.mem_ready;
    vif.write_signal <= item.write_signal;
    if (vif.stall_1 == 0)begin
    vif.read[1] <= item.read[1];
    vif.write[1] <= item.write[1];
    vif.pr_addr[1] <= item.pr_addr[1];
    vif.pr_data[1] <= item.pr_data[1];
    vif.Core_send[1] <= item.Core_send[1];
    vif.c_flush[1] <= item.c_flush[1];
    end
  endtask: drive
  
  
endclass: core_driver1
class core_monitor extends uvm_monitor;
  `uvm_component_utils(core_monitor)
  
  virtual core_interface vif;
  core_sequence_item item;
  
  uvm_analysis_port #(core_sequence_item) monitor_port;
  
  
  //--------------------------------------------------------
  //Constructor
  //--------------------------------------------------------
  function new(string name = "core_monitor", uvm_component parent);
    super.new(name, parent);
    `uvm_info("MONITOR_CLASS", "Inside Constructor!", UVM_HIGH)
  endfunction: new
  
  
  //--------------------------------------------------------
  //Build Phase
  //--------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("MONITOR_CLASS", "Build Phase!", UVM_HIGH)
    
    monitor_port = new("monitor_port", this);
    
    if(!(uvm_config_db #(virtual core_interface)::get(this, "*", "vif", vif))) begin
      `uvm_error("MONITOR_CLASS", "Failed to get VIF from config DB!")
    end
    
  endfunction: build_phase
  
  //--------------------------------------------------------
  //Connect Phase
  //--------------------------------------------------------
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info("MONITOR_CLASS", "Connect Phase!", UVM_HIGH)
    
  endfunction: connect_phase
  
  
  //--------------------------------------------------------
  //Run Phase
  //--------------------------------------------------------
  task run_phase (uvm_phase phase);
    super.run_phase(phase);
    `uvm_info("MONITOR_CLASS", "Inside Run Phase!", UVM_HIGH)
    
    forever begin
      item = core_sequence_item::type_id::create("item");
      
      
      wait(!vif.rst);
      
      //sample inputs
      @(posedge vif.clk);
      item.rst = vif.rst;
      item.read[0] = vif.read[0];
      item.write[0] = vif.write[0];
      item.pr_addr[0] =  vif.pr_addr[0];
      item.pr_data[0] = vif.pr_data[0];
      item.Core_send[0] =  vif.Core_send[0];
      item.c_flush[0] = vif.c_flush[0];
      item.mem_read_data = vif.mem_read_data;
      item.mem_ready = vif.mem_ready;
      item.write_signal = vif.write_signal;
      
      //sample output
      @(posedge vif.clk);
      item.data_out_pr[0] = vif.data_out_pr[0];
      item.stall = vif.stall;
      // send item to scoreboard
      monitor_port.write(item);
    end
        
  endtask: run_phase
  
  
endclass: core_monitor
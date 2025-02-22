
class core_env extends uvm_env;
  `uvm_component_utils(core_env)
  
  core_agent agnt;
  core_agent1 agnt1;
  core_agent2 agnt2;
  core_agent3 agnt3;
  core_scoreboard scb;
  
  
  //--------------------------------------------------------
  //Constructor
  //--------------------------------------------------------
  function new(string name = "core_env", uvm_component parent);
    super.new(name, parent);
    `uvm_info("ENV_CLASS", "Inside Constructor!", UVM_HIGH)
  endfunction: new
  
  
  //--------------------------------------------------------
  //Build Phase
  //--------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("ENV_CLASS", "Build Phase!", UVM_HIGH)
    
    agnt = core_agent::type_id::create("agnt", this);
    agnt1 = core_agent1::type_id::create("agnt1", this);
    agnt2 = core_agent2::type_id::create("agnt2", this);
    agnt3 = core_agent3::type_id::create("agnt3", this);
    scb = core_scoreboard::type_id::create("scb", this);
    
  endfunction: build_phase
  
  
  //--------------------------------------------------------
  //Connect Phase
  //--------------------------------------------------------
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info("ENV_CLASS", "Connect Phase!", UVM_HIGH)
    
    agnt.mon.monitor_port.connect(scb.scoreboard_port);
    agnt1.mon1.monitor_port.connect(scb.scoreboard_port1);
    agnt2.mon2.monitor_port.connect(scb.scoreboard_port2);
    agnt3.mon3.monitor_port.connect(scb.scoreboard_port3);
    
  endfunction: connect_phase
  
  
  //--------------------------------------------------------
  //Run Phase
  //--------------------------------------------------------
  task run_phase (uvm_phase phase);
    super.run_phase(phase);
    
  endtask: run_phase
  
  
endclass: core_env
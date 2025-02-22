
class core_test extends uvm_test;
  `uvm_component_utils(core_test)

  core_env env;
  core_base_sequence reset_seq;
  core_test_sequence test_seq;

  
  //--------------------------------------------------------
  //Constructor
  //--------------------------------------------------------
  function new(string name = "core_test", uvm_component parent);
    super.new(name, parent);
    `uvm_info("TEST_CLASS", "Inside Constructor!", UVM_HIGH)
  endfunction: new

  
  //--------------------------------------------------------
  //Build Phase
  //--------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("TEST_CLASS", "Build Phase!", UVM_HIGH)

    env = core_env::type_id::create("env", this);

  endfunction: build_phase

  
  //--------------------------------------------------------
  //Connect Phase
  //--------------------------------------------------------
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info("TEST_CLASS", "Connect Phase!", UVM_HIGH)

  endfunction: connect_phase

  
  //--------------------------------------------------------
  //Run Phase
  //--------------------------------------------------------
 task run_phase (uvm_phase phase);
  super.run_phase(phase);
  `uvm_info("TEST_CLASS", "Run Phase!", UVM_HIGH)

  phase.raise_objection(this);

  // Reset sequences
  fork
    begin
      reset_seq = core_base_sequence::type_id::create("reset_seq_0");
      reset_seq.start(env.agnt.seqr);
    end
    begin
      reset_seq = core_base_sequence::type_id::create("reset_seq_1");
      reset_seq.start(env.agnt1.seqr1);
    end
    begin
      reset_seq = core_base_sequence::type_id::create("reset_seq_2");
      reset_seq.start(env.agnt2.seqr2);
    end
    begin
      reset_seq = core_base_sequence::type_id::create("reset_seq_3");
      reset_seq.start(env.agnt3.seqr3);
    end
  join

  #10;

  // Test sequences
  repeat(100) begin
    fork
      begin
        test_seq = core_test_sequence::type_id::create("test_seq_0");
        test_seq.start(env.agnt.seqr);
      end
      begin
        test_seq = core_test_sequence::type_id::create("test_seq_1");
        test_seq.start(env.agnt1.seqr1);
      end
      begin
        test_seq = core_test_sequence::type_id::create("test_seq_2");
        test_seq.start(env.agnt2.seqr2);
      end
      begin
        test_seq = core_test_sequence::type_id::create("test_seq_3");
        test_seq.start(env.agnt3.seqr3);
      end
    join

    #10;
  end

  phase.drop_objection(this);
endtask: run_phase



endclass: core_test
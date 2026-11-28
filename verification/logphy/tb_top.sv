module tb_top;
  timeunit 1ns; timeprecision 1ps;

  logic clock = 1'b0;
  logic reset = 1'b1;

  always #5ns clock = ~clock;

  // Create the four interface instances.
  ucie_rdi_if rdi (
      .reset(reset),
      .lclk (clock)
  );

  logical_phy_control_if ctrl (.clock(clock), .reset(reset));
  logical_phy_status_if status (.clock(clock), .reset(reset));
  logical_phy_analog_if analog (.clock(clock), .reset(reset));

  logphy_wrapper dut (.rdi(rdi), .ctrl(ctrl), .status(status), .analog(analog));
  logphy_assertions rdi_assertions (.rdi(rdi), .lt_state(status.training.ltState));

  task automatic drive_rdi_idle();
    rdi.lp_irdy = 'b0;
    rdi.lp_valid = 'b0;
    rdi.lp_data = 'b0;
    rdi.lp_state_req = 'b0;
    rdi.lp_linkerror = 'b0;
    rdi.lp_stallack = 'b0;
    rdi.lp_clk_ack = 'b0;
    rdi.lp_wake_req = 'b0;
    rdi.lp_cfg = 'b0;
    rdi.lp_cfg_vld = 'b0;
    rdi.lp_cfg_crd = 'b0;
  endtask

  task automatic randomize_analog_inputs();
    analog.mainband_tx_ready = $urandom_range(1, 0);
    analog.mainband_rx.valid = $urandom_range(1, 0);

    foreach (analog.mainband_rx.data[lane]) begin
      analog.mainband_rx.data[lane] = $urandom();
    end

    analog.mainband_rx.valid_lane = $urandom();
    analog.mainband_rx.clkP = $urandom();
    analog.mainband_rx.clkN = $urandom();
    analog.mainband_rx.trk = $urandom();

    analog.status.pllLock = $urandom_range(1, 0);
    analog.status.clocksUngatedAndStable = $urandom_range(1, 0);
    analog.status.txSelfCalDone = $urandom_range(1, 0);

    analog.sideband_rx.bits = $urandom_range(1, 0);
    analog.sideband_rx.fwClock = $urandom_range(1, 0);
  endtask

  task automatic randomize_ctrl_inputs();
    ctrl.link_control.pwrGood = $urandom_range(1, 0);
    ctrl.link_control.retryTrainingAmt = $urandom();

    ctrl.local_params.valid = $urandom_range(1, 0);
    ctrl.local_params.voltageSwing = $urandom();
    ctrl.local_params.maxDataRate = $urandom();
    ctrl.local_params.clockMode = $urandom_range(1, 0);
    ctrl.local_params.clockPhase = $urandom_range(1, 0);
    ctrl.local_params.ucieSx8 = $urandom_range(1, 0);
    ctrl.local_params.sbFeatExt = $urandom_range(1, 0);
    ctrl.local_params.txAdjRuntime = $urandom_range(1, 0);
    ctrl.local_params.moduleId = $urandom();

    ctrl.training_params.clockPhase = $urandom();
    ctrl.training_params.dataPattern = $urandom();
    ctrl.training_params.validPattern = $urandom();
    ctrl.training_params.patternMode = $urandom_range(1, 0);
    ctrl.training_params.iterationCount = $urandom();
    ctrl.training_params.idleCount = $urandom();
    ctrl.training_params.burstCount = $urandom();
    ctrl.training_params.maxErrorThreshold = $urandom();
    ctrl.training_params.comparisonMode = $urandom_range(1, 0);

    ctrl.link_control.swStartLinkTraining = $urandom_range(1, 0);
    ctrl.link_control.swRetrainRequest = $urandom_range(1, 0);
    ctrl.link_control.linkOpParamOverride = $urandom_range(1, 0);
    ctrl.link_control.clockPhaseSelect = $urandom();
    ctrl.link_control.maxErrorThresholdPerLane = $urandom();
    ctrl.link_control.changeInRuntimeLinkCtrlRegsDetected = $urandom_range(1, 0);
    ctrl.link_control.runtimeLinkCtrlBusyBit = $urandom_range(1, 0);
    ctrl.link_control.runtimeRequestForRepair = $urandom_range(1, 0);
  endtask

  task automatic reset_dut();
    // drive all rdi lp signals to zero
    drive_rdi_idle();

    // Randomize unrelated analog and control inputs.
    randomize_analog_inputs();
    randomize_ctrl_inputs();

    // trigger reset
    reset = 1'b1;
    @(posedge clock);
    @(negedge clock);
    reset = 1'b0;
    @(posedge clock);
    @(negedge clock);
  endtask

  task automatic test_rdi_wake_with_clocks_ready();
    @(negedge clock);
    rdi.lp_wake_req = 1'b1;
    analog.status.clocksUngatedAndStable = 1'b0;
    repeat ($urandom_range(8, 1)) @(posedge clock);  // Model a delayed PHY clock
    if (rdi.pl_wake_ack !== 1'b0) $fatal(1, "pl_wake_ack asserted before PHY clocks were ready");
    @(negedge clock);
    analog.status.clocksUngatedAndStable = 1'b1;
    wait (rdi.pl_wake_ack === 1'b1);

    repeat ($urandom_range(8, 1)) @(posedge clock);  // Keep lp_wake_req high for more samples

    @(negedge clock);
    rdi.lp_wake_req = 1'b0;
    wait (rdi.pl_wake_ack === 1'b0);
  endtask

  initial begin
    reset_dut();
    test_rdi_wake_with_clocks_ready();
    $display("PASS: LogPHY tests");
    $finish;
  end
endmodule

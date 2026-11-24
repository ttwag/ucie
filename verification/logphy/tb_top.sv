module tb_top;
  timeunit 1ns; timeprecision 1ps;

  logic clock = 1'b0;
  logic reset = 1'b1;
  logic clocks_ready = 1'b0;

  always #5ns clock = ~clock;

  // Create the four interface instances.
  ucie_rdi_if rdi (
      .reset(reset),
      .lclk (clock)
  );

  logical_phy_afe_if afe (.reset(reset));

  logical_phy_sideband_if sideband (.reset(reset));

  logical_phy_control_if ctrl (
      .clock(clock),
      .reset(reset)
  );

  logphy_wrapper dut (.*);

  initial begin
    $display("PASS: LogPHY tests");
    $finish;
  end
endmodule

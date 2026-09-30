// nexys4_top.v - wraps top_nn for the physical Nexys 4 board.
// The 4 input values are hardcoded to the same test sample already proven
// correct in simulation (expected class = 0, setosa).
//   BTNC   = start (press it to run one classification)
//   RESET  = CPU RESET button (board reset)
//   LED[1:0] = predicted class (00, 01, or 10)
//   LED[2]   = done (lights up once the result is ready)
module nexys4_top (
    input  wire        clk,          // 100 MHz board clock
    input  wire        btnCpuReset,  // CPU RESET button
    input  wire        btnC,         // center button = start
    output wire [15:0] led
);

    // Clock divider: the design failed timing at the full 100 MHz board
    // clock (its combinational math paths take a bit too long per cycle).
    // We don't need speed for this demo, so run the network on a much
    // slower derived clock (100MHz / 32 = 3.125 MHz) to remove the
    // problem entirely, with large margin.
    reg [4:0] clkdiv = 5'd0;
    always @(posedge clk) clkdiv <= clkdiv + 1'b1;
    wire slow_clk = clkdiv[4];

    // Hardcoded Q8.8 fixed-point test vector (from test_input.mem)
    localparam signed [15:0] IN0 = 16'h0466;
    localparam signed [15:0] IN1 = 16'h0300;
    localparam signed [15:0] IN2 = 16'h014d;
    localparam signed [15:0] IN3 = 16'h0033;

    wire signed [4*16-1:0] in_vec = {IN3, IN2, IN1, IN0};

    wire [1:0] predicted_class;
    wire       done;

    top_nn #(.WIDTH(16), .FRAC(8)) dut (
        .clk(slow_clk),
        .rst(btnCpuReset),
        .start(btnC),
        .in_vec(in_vec),
        .predicted_class(predicted_class),
        .done(done)
    );

    assign led[1:0]  = predicted_class;
    assign led[2]    = done;
    assign led[15:3] = 13'b0;

endmodule

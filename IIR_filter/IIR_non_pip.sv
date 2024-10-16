module IIR #(
    parameter DATA_W = 24, // width of data
    parameter COEFF_W = 32, // width of coefficients
    parameter ORDER = 12, // order of iir filter
    parameter [(ORDER+1)*COEFF_W-1:0] COEFF_A = {32'd1048576, -32'd7538892, 32'd25522080, -32'd53578384, 32'd77454024, -32'd81047191, 32'd62832463, -32'd36309940, 32'd15504230, -32'd4765579, 32'd999994, -32'd128519, 32'd7645},
    parameter [(ORDER+1)*COEFF_W-1:0]  COEFF_B = {32'd0, 32'd1, 32'd8, 32'd27, 32'd61, 32'd98, 32'd114, 32'd98, 32'd61, 32'd27, 32'd8, 32'd1, 32'd0}
)(
    input logic clk,
    input logic reset_n,
    input signed [DATA_W-1:0] data_in,
    output signed [DATA_W-1:0] data_out
);

    logic signed [COEFF_W-1:0] coeff_a [ORDER+1];
    logic signed [COEFF_W-1:0] coeff_b [ORDER+1];

    //logic signed [63:0] z0;
    logic signed [63:0] z_reg[ORDER+1];
    logic signed [63:0] z_reg0;
    logic signed [63:0] za [ORDER+1];
    logic signed [63:0] zb [ORDER+1];
    logic signed [63:0] sub_w [ORDER+1];
    logic signed [63:0] add_w [ORDER+1];


    generate
        genvar i;
        for (i = 0; i <= ORDER; i++) begin : initial_a_coefficients
            assign coeff_a[ORDER-i] = COEFF_A[i*COEFF_W +: COEFF_W];
        end
        for (i = 0; i <= ORDER; i++) begin : initial_b_coefficients
            assign coeff_b[ORDER-i] = COEFF_B[i*COEFF_W +: COEFF_W];
        end
    endgenerate

    always_ff @(posedge clk) begin
        if (!reset_n) begin
            for (integer i = 1; i <= ORDER; i++) begin
                z_reg[i] <= 64'b0;
            end
        end
        else begin
            z_reg[1] <= z_reg0;
            for (integer i = 2; i <= ORDER; i++) begin
                z_reg[i] <= z_reg[i-1];
            end
        end
    end

    always_comb begin
        for (integer i = 1; i <= ORDER; i++) begin
            za[i] = z_reg[i] * coeff_a[i];
            zb[i] = z_reg[i] * coeff_b[i];
        end
        sub_w[1] = data_in - za[1];
        for (integer i = 2; i <= ORDER; i++) begin
            sub_w[i] = sub_w[i-1] - za[i];
        end
        z_reg0 = sub_w[ORDER];
        add_w[1] = sub_w[ORDER] * coeff_b[0] + zb[1];
        for (integer i = 2; i <= ORDER; i++) begin
            add_w[i] = add_w[i-1] + zb[i];
        end
    end

    assign data_out = add_w[ORDER] >>> 20;

endmodule

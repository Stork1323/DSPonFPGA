
module IIR_pipeline #(
    parameter DATA_W = 24, // width of data
    parameter COEFF_W = 32, // width of coefficients
    parameter ORDER = 4, // order of iir filter
    parameter FACTOR = 20, // number of shift bit for coefficients to avoid overflow 
    parameter [(ORDER+1)*COEFF_W-1:0] COEFF_A = {32'd1048576, -32'd3850087, 32'd5314181, -32'd3267328, 32'd754880},
    parameter [(ORDER+1)*COEFF_W-1:0]  COEFF_B = {32'd13, 32'd55, 32'd83, 32'd55, 32'd13}
)(
    input logic clk,
    input logic reset_n,
    input signed [DATA_W-1:0] data_in,
    output signed [DATA_W-1:0] data_out
);
 
    logic signed [COEFF_W-1:0] coeff_a [ORDER+1];
    logic signed [COEFF_W-1:0] coeff_b [ORDER+1];

    logic signed [63:0] x_b [ORDER+1];
    logic signed [63:0] y_a [ORDER+1];
    logic signed [63:0] f_d [ORDER+1];
    logic signed [63:0] f_q [ORDER+1];
    logic signed [63:0] f_q0;

    generate
        genvar i;
        for (i = 0; i <= ORDER; i++) begin : initial_a_coefficients
            assign coeff_a[ORDER-i] = COEFF_A[i*COEFF_W +: COEFF_W];
        end
        for (i = 0; i <= ORDER; i++) begin : initial_b_coefficients
            assign coeff_b[ORDER-i] = COEFF_B[i*COEFF_W +: COEFF_W];
        end
    endgenerate

    always_comb begin
        for (integer i = 0; i <= ORDER; i++) begin
            x_b[i] = coeff_b[i] * data_in;
        end
        for (integer i = 1; i <= ORDER; i++) begin
            y_a[i] = coeff_a[i] * f_q0;
        end
        for (integer i = 1; i < ORDER; i++) begin
            f_d[i] = x_b[i] + f_q[i+1] - y_a[i];
        end
        f_d[ORDER] = x_b[ORDER] - y_a[ORDER];
    end


    assign f_q0 = (f_q[1] + x_b[0]) >>> FACTOR;
    assign data_out = f_q0;

    always @ (posedge clk) 
    begin
        if (!reset_n)
        begin 
            for (integer i = 1; i <= ORDER; i++) begin
                f_q[i] <= 64'b0;
            end
        end
        else 
        begin
            for (integer i = 1; i <= ORDER; i++) begin
                f_q[i] <= f_d[i];
            end
        end
    end 
endmodule
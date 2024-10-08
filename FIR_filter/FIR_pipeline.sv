module FIR_pipeline #(
    parameter N_TAPS = 33, // number of taps
    parameter COEFF_W = 32, // width of coefficients
    parameter DATA_W = 24, // width of data in/out
    parameter [N_TAPS*COEFF_W-1:0] COEFFS = {-32'd12884901, -32'd10093173, -32'd12025908, -32'd12025908, -32'd9234179, -32'd2791728, 32'd7945689, 32'd23192823, 32'd42949672, 32'd66142496, 32'd92127048, 32'd118755845, 32'd144310901, 32'd166859479, 32'd184468845, 32'd195635760, 32'd199501230, 32'd195635760, 32'd184468845, 32'd166859479, 32'd144310901, 32'd118755845, 32'd92127048, 32'd66142496, 32'd42949672, 32'd23192823, 32'd7945689, -32'd2791728, -32'd9234179, -32'd12025908, -32'd12025908, -32'd10093173, -32'd12884901} // coefficients
)(
    input logic clk,
    input logic reset_n,
    input logic [DATA_W-1:0] data_in,
    output logic [DATA_W-1:0] data_out
);

    logic signed [31:0] Areg_q; // Areg_q contain delay data
    logic signed [63:0] Mreg_d [0:N_TAPS-1];
    logic signed [63:0] Mreg_q [0:N_TAPS-1];
    logic signed [63:0] Preg_d [0:N_TAPS-1];
    logic signed [63:0] Preg_q [0:N_TAPS-1];
    logic signed [COEFF_W-1:0] coeffs [0:N_TAPS-1]; // coefficients array

    localparam SHIFT_BIT = COEFF_W - DATA_W;

    generate
        genvar i;
        for (i = 0; i < N_TAPS; i=i+1) begin : initial_coeffs
            assign coeffs[i] = COEFFS[i*COEFF_W +: COEFF_W];
        end
    endgenerate

    always @(posedge clk) begin
        integer i;
        if (!reset_n) begin
            Areg_q <= 32'd0;
            for (i = 0; i < N_TAPS; i=i+1)  begin
                Mreg_q[i] <= 64'd0;
                Preg_q[i] <= 64'd0;
            end
        end 
        else begin
            Areg_q <= {data_in, {SHIFT_BIT{1'b0}}};
            for (i = 0; i < N_TAPS; i=i+1)  begin
                Mreg_q[i] <= Mreg_d[i];
                Preg_q[i] <= Preg_d[i];
            end
        end
    end

    always_comb begin
        integer i, j;
        for (i = 0; i < N_TAPS; i=i+1) begin
            Mreg_d[i] = Areg_q * coeffs[i];
        end
        for (j = 0; j < N_TAPS-1; j=j+1) begin
            Preg_d[j] = Mreg_q[j] + Preg_q[j+1];
        end
        Preg_d[N_TAPS-1] = Mreg_q[N_TAPS-1];
    end

    assign data_out = (Preg_d[0] >>> (64-DATA_W));

endmodule
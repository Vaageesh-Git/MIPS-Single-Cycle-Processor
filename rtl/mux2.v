module mux2 #(
    parameter W = 32
) (
    input  wire [W-1:0] d0,
    input  wire [W-1:0] d1,
    input  wire         sel,
    output wire [W-1:0] y
);

    assign y = sel ? d1 : d0;

endmodule

`timescale 1us/1ps

module tb;

    logic clk = 0;
    logic rst;
    logic [31:0] send_A;
    logic [31:0] send_B;
    logic [31:0] result;

FPU dut(
     .clock_100Khz(clk),
     .reset(rst), 
     .Op_A_in(send_A),
     .Op_B_in(send_B),
     .data_out(result),
     .status_out(op_status)
);

always begin #5; clk <= ~clk; end // periodo de 10 us, frequencia de 100KHz

initial begin
    // Reset inicial
    rst <= 0;
    #10 rst <= 1;

    // Teste 1: Soma de 2.0 + 1.0
    //send_A = {1'b0, 10'b1000000000, 21'b000000000000000000000}; // 2.0
    //send_B = {1'b0, 10'b0111111111, 21'b000000000000000000000}; // 1.0
    //#100;
    
    // Teste 2: Subtração 5.75 - 1.25
    send_A = {1'b0, 10'b1000000101, 21'b000000000000000000000}; // 5.75
    send_B = {1'b0, 10'b1000000000, 21'b010000000000000000000}; // 1.25 (0.25 mantissa = 010...)
    #100;
    
    // Teste 3: Soma com zero (3.0 + 0.0)
    send_A = {1'b0, 10'b1000000011, 21'b000000000000000000000}; // 3.0
    send_B = {1'b0, 10'b0000000000, 21'b000000000000000000000}; // 0.0
    #100;
    
    // Teste 4: Subtração com zero (-2.0 + 0.0)
    send_A = {1'b1, 10'b1000000000, 21'b000000000000000000000}; // -2.0
    send_B = {1'b0, 10'b0000000000, 21'b000000000000000000000}; // 0.0
    #100;
    
    // Teste 5: Overflow simulado (1e10 + 1e10)
    send_A = {1'b0, 10'b1010000100, 21'b100110110010101000111}; // ~1e10
    send_B = {1'b0, 10'b1010000100, 21'b100110110010101000111}; // ~1e10
    #100;
    
    // Teste 6: Underflow simulado (1e-10 + 1e-10)
    send_A = {1'b0, 10'b0100110110, 21'b111001101011001001111}; // ~1e-10
    send_B = {1'b0, 10'b0100110110, 21'b111001101011001001111}; // ~1e-10
    #100;
    
    // Teste 7: Cancelamento total (8.0 + -8.0)
    send_A = {1'b0, 10'b1000000100, 21'b000000000000000000000}; // 8.0
    send_B = {1'b1, 10'b1000000100, 21'b000000000000000000000}; // -8.0
    #100;
    
    // Teste 8: Soma de iguais (4.5 + 4.5)
    send_A = {1'b0, 10'b1000000010, 21'b100000000000000000000}; // 4.5
    send_B = {1'b0, 10'b1000000010, 21'b100000000000000000000}; // 4.5
    #100;
    
    // Teste 9: Subtração parcial (7.0 + -3.0)
    send_A = {1'b0, 10'b1000000011, 21'b110000000000000000000}; // 7.0
    send_B = {1'b1, 10'b1000000011, 21'b000000000000000000000}; // -3.0
    #100;
    
    // Teste 10: Diferença de expoentes grande (1024.0 + 1.0)
    send_A = {1'b0, 10'b1001000000, 21'b000000000000000000000}; // 1024.0
    send_B = {1'b0, 10'b0111111111, 21'b000000000000000000000}; // 1.0
    #100;
    
    
end

endmodule
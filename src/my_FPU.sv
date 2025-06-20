// clk de 100Khz

typedef enum logic[3:0]{
    DECODE,
    ALIGN,
    OPERATE,
    NORMALIZE,
    WRITEBACK
} state_t;

typedef enum logic[3:0] { 
    OVERFLOW,
    UNDERFLOW,
    EXACT,
    INEXACT
} status_t;

module FPU(
    input logic clock_100Khz,
    input logic reset, // assincrono
    input logic [31:0] Op_A_in,
    input logic [31:0] Op_B_in,
    output logic [31:0] data_out,
    output status_t status_out
);

state_t EA, PE;
logic sign_A, sign_B, carry, compare, start, done_decode, done_align, done_operate, done_writeback, done_normalize, sign_A_tmp, sign_B_tmp, helper;
logic [21:0] mant_A, mant_B, mant_TMP, mant_A_tmp, mant_B_tmp;
logic [9:0] exp_A, exp_B, exp_TMP, exp_A_tmp, exp_B_tmp; // vou ter que ver quantos espaços precisa
logic [9:0] diff_Exponent;

always_ff @(posedge clock_100Khz or negedge reset) begin
    if(!reset) begin
        EA <= DECODE;
    end else begin
        EA <= PE;
    end
end

always_comb begin
    PE = EA; // valor padrão
    case (EA)
        DECODE: PE = (done_decode)? ALIGN : DECODE;
      
        ALIGN: PE = (done_align)? OPERATE : ALIGN;
        
        OPERATE: PE = (done_operate)? NORMALIZE : OPERATE; 
       
        NORMALIZE:   PE = (done_normalize)? WRITEBACK : NORMALIZE;

        WRITEBACK:  PE = (done_writeback)? DECODE : WRITEBACK;

        default:     PE = DECODE;
    endcase
end

always_comb begin
            compare = (Op_A_in[30:21] >= Op_B_in[30:21])? 1'b1 : 1'b0; // ve qual é maior ou se são iguais
            mant_A_tmp = compare ? {1'b1,Op_A_in[20:0]} : {1'b1,Op_B_in[20:0]}; // armazena mant do maior em A
            exp_A_tmp  = compare ? (Op_A_in[30:21]) : (Op_B_in[30:21]);             // exp do maior em A
            sign_A_tmp = compare ? Op_A_in[31] : Op_B_in[31];                   // sinal do maior

            mant_B_tmp = compare ? {1'b1,Op_B_in[20:0]} : {1'b1,Op_A_in[20:0]};  // armazena mant do outro em B
            exp_B_tmp  = compare ? (Op_B_in[30:21]) : (Op_A_in[30:21]);             // exp do outro em B
            sign_B_tmp = compare ? Op_B_in[31] : Op_A_in[31];                    // sinal do outro
            diff_Exponent = exp_A_tmp - exp_B_tmp;
end
    

always_ff @(posedge clock_100Khz or negedge reset) begin
    if(!reset) begin
            data_out <= 32'd0;
            status_out <= EXACT;
            mant_TMP <= 22'd0;
            exp_TMP <= 10'd0;
            start <= 1;
            done_decode <= 0;
            done_align <= 0;
            done_operate <= 0;
            done_writeback <= 0;
            done_normalize <= 0;
    end else begin

        case(EA) 
            DECODE: begin
                if(start) begin
                    mant_A <= mant_A_tmp;
                    exp_A <= exp_A_tmp;
                    sign_A <= sign_A_tmp;

                    mant_B <= mant_B_tmp;
                    exp_B <= exp_B_tmp;
                    sign_B <= sign_B_tmp;

                    start <= 0;
                    done_decode <= 1;
                end
                else begin 
                    start <= 1;
                end
            end
            ALIGN: begin
                mant_B <= mant_B >> diff_Exponent; // shift right em mant_B para alinhar
                done_align <= 1;
            end
            OPERATE: begin
                if (sign_A == sign_B) begin 
                        {carry, mant_TMP} <= mant_A + mant_B;   // soma se forem de sinais iguais, pega o bit carry por concatenação
                    end else begin
                        mant_TMP <= mant_A - mant_B;            // subtrai se forem de diferentes
                        carry    <= 1'b0;                       // sub não tem carry nunca
                    end

                    exp_TMP <= exp_A;

                    if (carry) begin                    // arruma o numero caso houver carry
                        mant_TMP <= (mant_TMP >> 1);
                        exp_TMP  <= exp_TMP + 1;
                    end
                    done_operate <= 1;
            end
            NORMALIZE: begin
                    if (mant_TMP == 0) begin
                        helper <= 1; 
                    end else if (mant_TMP[21]) begin
                        helper <= 1;
                    end else begin
                        mant_TMP <= mant_TMP << 1;
                        exp_TMP  <= exp_TMP - 1;
                        helper <= 0;
                    end

                    if (helper == 1) begin

                        if (exp_TMP == 10'd0) begin
                        status_out <= UNDERFLOW;
                        end else if (exp_TMP == 10'd1023) begin
                            status_out <= OVERFLOW;
                        end else if (mant_TMP[20:0] == 21'd0) begin
                            status_out <= INEXACT;
                        end else begin
                            status_out <= EXACT;
                        end

                        done_normalize <= 1;
                    end
            end
            WRITEBACK: begin
                    data_out  <= {sign_A, exp_TMP, mant_TMP[20:0]};

                    done_writeback <= 1;
            end
        endcase
    end
end
endmodule
typedef enum logic[3:0] {
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
    input  logic        clock_100Khz,
    input  logic        reset,      // assíncrono ativo-baixo
    input  logic [31:0] Op_A_in,
    input  logic [31:0] Op_B_in,
    output logic [31:0] data_out,
    output status_t     status_out
);

    state_t EA, PE;

    // sinais auxiliares
    logic sign_A, sign_B, carry, compare;
    logic helper;
    logic done_decode, done_align, done_operate, done_normalize, done_writeback;

    // campos de mantissa e expoente
    logic [21:0] mant_A, mant_B, mant_TMP, mant_A_tmp, mant_B_tmp;
    logic [9:0]  exp_A, exp_B, exp_TMP, exp_A_tmp, exp_B_tmp;
    logic [9:0]  diff_Exponent;

    // FSM sequencial (transições + estado)
    always_ff @(posedge clock_100Khz or negedge reset) begin
        if (!reset) begin
            EA             <= DECODE;
            // reset flags
            done_decode    <= 1'b0;
            done_align     <= 1'b0;
            done_operate   <= 1'b0;
            done_normalize <= 1'b0;
            done_writeback <= 1'b0;
            helper         <= 1'b0;
            // reset regs
            mant_A         <= 22'd0;
            mant_B         <= 22'd0;
            mant_TMP       <= 22'd0;
            exp_A          <= 10'd0;
            exp_B          <= 10'd0;
            exp_TMP        <= 10'd0;
            sign_A         <= 1'b0;
            sign_B         <= 1'b0;
            data_out       <= 32'd0;
            status_out     <= EXACT;
        end else begin
            // estado
            EA <= PE;
            // executar ação de cada estado
            case (EA)
                DECODE: begin
                    // carrega operandos prontos
                    mant_A       <= mant_A_tmp;
                    exp_A        <= exp_A_tmp;
                    sign_A       <= compare ? Op_A_in[31] : Op_B_in[31];
                    mant_B       <= mant_B_tmp;
                    exp_B        <= exp_B_tmp;
                    sign_B       <= compare ? Op_B_in[31] : Op_A_in[31];
                    done_decode  <= 1'b1;
                end

                ALIGN: begin
                    // shift B para alinhar expoentes
                    mant_B     <= mant_B >> diff_Exponent;
                    done_align <= 1'b1;
                end

                OPERATE: begin
                    // soma ou subtrai mantissas
                    if (sign_A == sign_B) begin
                        {carry, mant_TMP} <= mant_A + mant_B;
                    end else begin
                        mant_TMP <= mant_A - mant_B;
                        carry    <= 1'b0;
                    end
                    exp_TMP <= exp_A;
                    // corrige overflow de mantissa
                    if (carry) begin
                        mant_TMP <= mant_TMP >> 1;
                        exp_TMP  <= exp_TMP + 1;
                    end
                    done_operate <= 1'b1;
                end

                NORMALIZE: begin
                    // só faz normalize se ainda não finalizado
                    if (!done_normalize) begin
                        // limpa helper ao entrar
                        helper <= 1'b0;
                        // shift até MSB em bit21
                        if (!mant_TMP[21]) begin
                            mant_TMP <= mant_TMP << 1;
                            exp_TMP  <= exp_TMP - 1;
                        end else begin
                            done_normalize <= 1'b1;
                        end
                    end
                end

                WRITEBACK: begin
                    // monta saída e status
                    data_out <= {sign_A, exp_TMP, mant_TMP[20:0]};
                    if (exp_TMP == 10'd0)              status_out <= UNDERFLOW;
                    else if (exp_TMP == 10'd1023)      status_out <= OVERFLOW;
                    else if (mant_TMP[20:0] == 21'd0)  status_out <= INEXACT;
                    else                                 status_out <= EXACT;
                    done_writeback <= 1'b1;
                end
            endcase
        end
    end

    // FSM combinacional
    always_comb begin
        PE = EA;
        case (EA)
            DECODE:    if (done_decode)    PE = ALIGN;
            ALIGN:     if (done_align)     PE = OPERATE;
            OPERATE:   if (done_operate)   PE = NORMALIZE;
            NORMALIZE: if (done_normalize) PE = WRITEBACK;
            WRITEBACK: if (done_writeback) PE = DECODE;
            default:   PE = DECODE;
        endcase
    end

    // preparação de operandos
    always_comb begin
        compare       = (Op_A_in[30:21] >= Op_B_in[30:21]);
        mant_A_tmp    = compare ? {1'b1, Op_A_in[20:0]} : {1'b1, Op_B_in[20:0]};
        exp_A_tmp     = compare ? Op_A_in[30:21]       : Op_B_in[30:21];
        mant_B_tmp    = compare ? {1'b1, Op_B_in[20:0]} : {1'b1, Op_A_in[20:0]};
        exp_B_tmp     = compare ? Op_B_in[30:21]       : Op_A_in[30:21];
        diff_Exponent = exp_A_tmp - exp_B_tmp;
    end

endmodule

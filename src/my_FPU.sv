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
    input  logic        reset,       // assíncrono ativo-baixo
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

    // Máquina de estado seqüencial
    always_ff @(posedge clock_100Khz or negedge reset) begin
        if (!reset) begin
            EA            <= DECODE;
            // reset de todas as flags
            done_decode   <= 1'b0;
            done_align    <= 1'b0;
            done_operate  <= 1'b0;
            done_normalize<= 1'b0;
            done_writeback<= 1'b0;
            helper        <= 1'b0;
            // reset dos registros intermediários
            mant_A        <= 22'd0;
            mant_B        <= 22'd0;
            mant_TMP      <= 22'd0;
            exp_A         <= 10'd0;
            exp_B         <= 10'd0;
            exp_TMP       <= 10'd0;
            sign_A        <= 1'b0;
            sign_B        <= 1'b0;
            data_out      <= 32'd0;
            status_out    <= EXACT;
        end else begin
            EA <= PE;
            // limpar flags de estados que não sejam o atual
            if (EA != DECODE)    done_decode    <= 1'b0;
            if (EA != ALIGN)     done_align     <= 1'b0;
            if (EA != OPERATE)   done_operate   <= 1'b0;
            if (EA != NORMALIZE) done_normalize <= 1'b0;
            if (EA != WRITEBACK) done_writeback <= 1'b0;

            case (EA)
                // --- Carrega operandos num ciclo ---
                DECODE: begin
                    // comparação e pré-carregamento já prontos no combinacional
                    mant_A       <= mant_A_tmp;
                    exp_A        <= exp_A_tmp;
                    sign_A       <= compare ? Op_A_in[31] : Op_B_in[31];
                    mant_B       <= mant_B_tmp;
                    exp_B        <= exp_B_tmp;
                    sign_B       <= compare ? Op_B_in[31] : Op_A_in[31];
                    done_decode  <= 1'b1;
                end

                // --- Alinha mantissas ---
                ALIGN: begin
                    // shift right da mantissa B
                    mant_B     <= mant_B >> diff_Exponent;
                    done_align <= 1'b1;
                end

                // --- Soma ou subtrai mantissas ---
                OPERATE: begin
                    if (sign_A == sign_B) begin
                        {carry, mant_TMP} <= mant_A + mant_B;
                    end else begin
                        mant_TMP <= mant_A - mant_B;
                        carry    <= 1'b0;
                    end
                    exp_TMP <= exp_A;
                    // trata overflow de mantissa
                    if (carry) begin
                        mant_TMP <= mant_TMP >> 1;
                        exp_TMP  <= exp_TMP + 1;
                    end
                    done_operate <= 1'b1;
                end

                // --- Normaliza resultado ---
                NORMALIZE: begin
                    // só faz shift enquanto MSB não estiver em mant_TMP[21]
                    if (!done_normalize) begin
                        if (mant_TMP == 0) begin
                            helper <= 1'b1;
                        end else if (!mant_TMP[21]) begin
                            mant_TMP <= mant_TMP << 1;
                            exp_TMP  <= exp_TMP - 1;
                        end else begin
                            helper <= 1'b1;
                        end
                        if (helper) begin
                            done_normalize <= 1'b1;
                        end
                    end
                end

                // --- Monta saída e status ---
                WRITEBACK: begin
                    data_out       <= {sign_A, exp_TMP, mant_TMP[20:0]};
                    // calcula status no mesmo ciclo
                    if (exp_TMP == 10'd0)                 status_out <= UNDERFLOW;
                    else if (exp_TMP == 10'd1023)         status_out <= OVERFLOW;
                    else if (mant_TMP[20:0] == 21'd0)     status_out <= INEXACT;
                    else                                   status_out <= EXACT;
                    done_writeback <= 1'b1;
                end
            endcase
        end
    end

    // Máquina combinacional de transição
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

    // Separação de campos e cálculo de diferença de expoentes
    always_comb begin
        compare      = (Op_A_in[30:21] >= Op_B_in[30:21]);
        mant_A_tmp   = compare ? {1'b1, Op_A_in[20:0]} : {1'b1, Op_B_in[20:0]};
        exp_A_tmp    = compare ? Op_A_in[30:21]       : Op_B_in[30:21];
        mant_B_tmp   = compare ? {1'b1, Op_B_in[20:0]} : {1'b1, Op_A_in[20:0]};
        exp_B_tmp    = compare ? Op_B_in[30:21]       : Op_A_in[30:21];
        diff_Exponent= exp_A_tmp - exp_B_tmp;
    end

endmodule

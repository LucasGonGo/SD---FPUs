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

    // Sinais auxiliares
    logic sign_A, sign_B, carry, carry_flag, compare, sticky_bit;
    logic done_decode, done_align, done_operate, done_normalize, done_writeback;

    logic [21:0] mant_A, mant_SHIFT, mant_B, mant_TMP, mant_A_tmp, mant_B_tmp;
    logic [9:0]  exp_A, exp_B, exp_TMP, exp_A_tmp, exp_B_tmp;
    logic [9:0]  diff_Exponent;

    // FSM Sequencial
    always_ff @(posedge clock_100Khz or negedge reset) begin
        if (!reset) begin
            EA             <= DECODE;
            done_decode    <= 0;
            done_align     <= 0;
            done_operate   <= 0;
            done_normalize <= 0;
            done_writeback <= 0;
            mant_A         <= 0;
            mant_B         <= 0;
            mant_SHIFT     <= 0;
            mant_TMP       <= 0;
            exp_A          <= 0;
            exp_B          <= 0;
            exp_TMP        <= 0;
            sign_A         <= 0;
            sign_B         <= 0;
            data_out       <= 0;
            status_out     <= EXACT;
            diff_Exponent  <= 0;
            carry_flag     <= 0;
        end else begin
            EA <= PE;

            case (EA)
                DECODE: begin
                    mant_A      <= mant_A_tmp;
                    exp_A       <= exp_A_tmp;
                    sign_A      <= compare ? Op_A_in[31] : Op_B_in[31];
                    mant_B      <= mant_B_tmp;
                    exp_B       <= exp_B_tmp;
                    sign_B      <= compare ? Op_B_in[31] : Op_A_in[31];
                    diff_Exponent <= exp_A_tmp - exp_B_tmp;
                    done_decode <= 1;
                end

                ALIGN: begin
                    if (diff_Exponent != 0) begin
                        if (diff_Exponent > 22) begin
                            mant_SHIFT <= 0;
                            sticky_bit <= 1;  
                        end else begin
                            mant_SHIFT <= mant_B >> diff_Exponent;
                            sticky_bit <= |(mant_B & ((1 << diff_Exponent) - 1));
                        end
                    end else begin
                        mant_SHIFT <= mant_B;
                        sticky_bit <= 0;
                    end
                    done_align <= 1;
                end


                OPERATE: begin
                    if (sign_A == sign_B) begin
                            {carry, mant_TMP} <= mant_A + mant_SHIFT;

                            if (sticky_bit && mant_TMP[0]) begin
                                  mant_TMP <= mant_TMP + 1;
                            end

                            exp_TMP <= exp_A;
                    end else begin
                        if (mant_A == mant_SHIFT) begin
                            mant_TMP <= 0;
                            exp_TMP <= 0;
                            sign_A   <= 0;
                            carry    <= 0;
                        end else if (mant_A >= mant_SHIFT) begin
                            mant_TMP <= mant_A - mant_SHIFT;
                            exp_TMP <= exp_A;
                            carry <= 0;
                        end else begin
                            mant_TMP <= mant_SHIFT - mant_A;
                            exp_TMP <= exp_A;
                            carry <= 0;
                            sign_A <= ~sign_A;
                        end
                    end
                    carry_flag <= carry;
                    done_operate <= 1;
                end

                NORMALIZE: begin
                    if (!done_normalize) begin
                        if (carry_flag) begin
                            mant_TMP <= mant_TMP >> 1;
                            exp_TMP  <= exp_TMP + 1;
                            carry_flag <= 0;
                        end else if (mant_TMP[21] == 0 && exp_TMP > 0) begin
                            mant_TMP <= mant_TMP << 1;
                            exp_TMP  <= exp_TMP - 1;
                        end else begin
                            done_normalize <= 1;
                        end
                    end
                end

                WRITEBACK: begin
                    data_out <= {sign_A, exp_TMP, mant_TMP[20:0]};

                    if (exp_TMP == 10'd0 && mant_TMP[20:0] == 0)
                        status_out <= EXACT; 
                    else if (exp_TMP == 10'd0)
                        status_out <= UNDERFLOW;
                    else if (exp_TMP == 10'd1023)
                        status_out <= OVERFLOW;
                    else
                        status_out <= EXACT;

                    done_writeback <= 1;
                end
            endcase
        end
    end

    // FSM Combinacional
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

    // Separação de campos
    always_comb begin
        compare    = (Op_A_in[30:21] >= Op_B_in[30:21]);
        mant_A_tmp = compare ? {1'b1, Op_A_in[20:0]} : {1'b1, Op_B_in[20:0]};
        exp_A_tmp  = compare ? Op_A_in[30:21]        : Op_B_in[30:21];
        mant_B_tmp = compare ? {1'b1, Op_B_in[20:0]} : {1'b1, Op_A_in[20:0]};
        exp_B_tmp  = compare ? Op_B_in[30:21]        : Op_A_in[30:21];
    end

endmodule

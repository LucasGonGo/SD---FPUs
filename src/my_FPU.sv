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
    input logic clock_100Khz,
    input logic reset,
    input logic [31:0] Op_A_in,
    input logic [31:0] Op_B_in,
    output logic [31:0] data_out,
    output status_t status_out
);

state_t EA, PE;

logic sign_A, sign_B, carry, sign_A_tmp, sign_B_tmp;
logic compare;
logic start;
logic done_decode, done_align, done_operate, done_normalize, done_writeback;
logic helper;

logic [21:0] mant_A, mant_B, mant_TMP, mant_A_tmp, mant_B_tmp;
logic [9:0] exp_A, exp_B, exp_TMP, exp_A_tmp, exp_B_tmp;
logic [9:0] diff_Exponent;

always_ff @(posedge clock_100Khz or negedge reset) begin
    if(!reset) EA <= DECODE;
    else EA <= PE;
end


always_comb begin
    PE = EA;

    case(EA)
        DECODE:    if(done_decode)    PE = ALIGN;
        ALIGN:     if(done_align)     PE = OPERATE;
        OPERATE:   if(done_operate)   PE = NORMALIZE;
        NORMALIZE: if(done_normalize) PE = WRITEBACK;
        WRITEBACK: if(done_writeback) PE = DECODE;
        default:   PE = DECODE;
    endcase
end

always_comb begin
    compare = (Op_A_in[30:21] >= Op_B_in[30:21]);
    
    mant_A_tmp = compare ? {1'b1, Op_A_in[20:0]} : {1'b1, Op_B_in[20:0]};
    exp_A_tmp  = compare ? Op_A_in[30:21] : Op_B_in[30:21];
    sign_A_tmp = compare ? Op_A_in[31] : Op_B_in[31];

    mant_B_tmp = compare ? {1'b1, Op_B_in[20:0]} : {1'b1, Op_A_in[20:0]};
    exp_B_tmp  = compare ? Op_B_in[30:21] : Op_A_in[30:21];
    sign_B_tmp = compare ? Op_B_in[31] : Op_A_in[31];

    diff_Exponent = exp_A_tmp - exp_B_tmp;
end

always_ff @(posedge clock_100Khz or negedge reset) begin
    if(!reset) begin
        data_out <= 0;
        status_out <= EXACT;
        mant_TMP <= 0;
        exp_TMP <= 0;
        mant_A <= 0;
        mant_B <= 0;
        exp_A <= 0;
        exp_B <= 0;
        sign_A <= 0;
        sign_B <= 0;

        start <= 1;

        done_decode <= 0;
        done_align <= 0;
        done_operate <= 0;
        done_normalize <= 0;
        done_writeback <= 0;

        helper <= 0;
    end else begin

        if (EA != WRITEBACK) done_writeback <= 0;

        case(EA)
            DECODE: begin
                if(start) begin
                    mant_A <= mant_A_tmp;
                    exp_A <= exp_A_tmp;
                    sign_A <= sign_A_tmp;

                    mant_B <= mant_B_tmp;
                    exp_B <= exp_B_tmp;
                    sign_B <= sign_B_tmp;

                    done_decode <= 1;
                    start <= 0;
                end else begin
                    done_decode <= 0;
                    start <= 1;
                end
                done_align <= 0;
                done_operate <= 0;
                done_normalize <= 0;
            end

            ALIGN: begin
                mant_B <= mant_B >> diff_Exponent;
                done_align <= 1;
                done_operate <= 0;
                done_normalize <= 0;
            end

            OPERATE: begin
                if (sign_A == sign_B) begin
                    {carry, mant_TMP} <= mant_A + mant_B;
                end else begin
                    mant_TMP <= mant_A - mant_B;
                    carry <= 0;
                end
                exp_TMP <= exp_A;

                if (carry) begin
                    mant_TMP <= mant_TMP >> 1;
                    exp_TMP <= exp_TMP + 1;
                end

                done_operate <= 1;
                done_normalize <= 0;
            end

            NORMALIZE: begin
                if (mant_TMP == 0) begin
                    helper <= 1;
                end else if (!mant_TMP[21]) begin
                    mant_TMP <= mant_TMP << 1;
                    exp_TMP <= exp_TMP - 1;
                    helper <= 0;
                end else begin
                    helper <= 1;
                end

                if (helper) begin
                    if (exp_TMP == 10'd0) status_out <= UNDERFLOW;
                    else if (exp_TMP == 10'd1023) status_out <= OVERFLOW;
                    else if (mant_TMP[20:0] == 0) status_out <= INEXACT;
                    else status_out <= EXACT;

                    done_normalize <= 1;
                end
            end

            WRITEBACK: begin
                data_out <= {sign_A, exp_TMP, mant_TMP[20:0]};
                done_writeback <= 1;

                done_decode <= 0;
                done_align <= 0;
                done_operate <= 0;
                done_normalize <= 0;
            end
        endcase
    end
end

endmodule

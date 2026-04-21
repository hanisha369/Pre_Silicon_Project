module tb_mm_accelerator;


// Parameters

localparam N           = 4;
localparam DATA_WIDTH  = 8;
localparam ACCUM_WIDTH = 32;
localparam CLK_PERIOD  = 10; // 100MHz


// DUT signals

logic                       clk;
logic                       rst_n;
logic                       start;
logic [N*DATA_WIDTH-1:0]    a_in;
logic [N*DATA_WIDTH-1:0]    b_in;
logic                       valid_in_upstream;
logic                       ready;
logic                       result_valid;
logic [N*N*ACCUM_WIDTH-1:0] result;


// DUT instantiation

mm_accelerator_top #(
        .N          (N),
        .DATA_WIDTH (DATA_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH)
) u_dut (
        .clk              (clk),
        .rst_n            (rst_n),
        .start            (start),
        .a_in             (a_in),
        .b_in             (b_in),
        .valid_in_upstream(valid_in_upstream),
        .ready            (ready),
        .result_valid     (result_valid),
        .result           (result)
);


// Clock generation

initial clk = 0;
always #(CLK_PERIOD/2) clk = ~clk;


// Helper \u2014 pack a flat 2D array into a bus
// matrix[row] maps to lane [row*DATA_WIDTH +: DATA_WIDTH]

function automatic logic [N*DATA_WIDTH-1:0] pack_row(
        input logic [DATA_WIDTH-1:0] mat [N][N],
        input int                    col
);
        logic [N*DATA_WIDTH-1:0] bus;
        for (int i = 0; i < N; i++)
                bus[i*DATA_WIDTH +: DATA_WIDTH] = mat[i][col];
        return bus;
endfunction

function automatic logic [N*DATA_WIDTH-1:0] pack_col(
        input logic [DATA_WIDTH-1:0] mat [N][N],
        input int                    row
);
        logic [N*DATA_WIDTH-1:0] bus;
        for (int j = 0; j < N; j++)
                bus[j*DATA_WIDTH +: DATA_WIDTH] = mat[row][j];
        return bus;
endfunction


// Helper \u2014 read result bus into 2D array

function automatic void unpack_result(
        input  logic [N*N*ACCUM_WIDTH-1:0] res_bus,
        output logic [ACCUM_WIDTH-1:0]     res_mat [N][N]
);
        for (int i = 0; i < N; i++)
                for (int j = 0; j < N; j++)
                        res_mat[i][j] = res_bus[(i*N+j)*ACCUM_WIDTH +: ACCUM_WIDTH];
endfunction


// Helper \u2014 software reference model

function automatic void ref_model(
        input  logic [DATA_WIDTH-1:0]  A [N][N],
        input  logic [DATA_WIDTH-1:0]  B [N][N],
        output logic [ACCUM_WIDTH-1:0] C [N][N]
);
        for (int i = 0; i < N; i++)
                for (int j = 0; j < N; j++) begin
                        C[i][j] = '0;
                        for (int k = 0; k < N; k++)
                                C[i][j] += ACCUM_WIDTH'(A[i][k]) * ACCUM_WIDTH'(B[k][j]);
                end
endfunction

initial begin
    $fsdbDumpfile("novas.fsdb");
    $fsdbDumpvars(0, tb_mm_accelerator);
end
endmodule

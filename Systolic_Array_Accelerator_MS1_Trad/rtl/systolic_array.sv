module systolic_array #(
	parameter N		= 4,
	parameter DATA_WIDTH	= 8,
	parameter ACCUM_WIDTH	= 32
)(
	input  logic			   clk, rst_n,
	input  logic [N*DATA_WIDTH-1:0]	   a_row,
	input  logic [N*DATA_WIDTH-1:0]	   b_col,
	input  logic			   valid_in,
	output logic [N*N*ACCUM_WIDTH-1:0] result,
	output logic			   valid_out,
	input  logic			   clear
);

wire [DATA_WIDTH-1:0] a_wire [N][N+1];
wire [DATA_WIDTH-1:0] b_wire [N+1][N];
wire [ACCUM_WIDTH-1:0] result_wire [N][N];

logic valid_diag [N][N];
logic [DATA_WIDTH-1:0] a_boundary [N];
logic [DATA_WIDTH-1:0] b_boundary [N];

always_ff @(posedge clk) begin
	if(!rst_n) begin
		for (int i=0; i<N; i++)
			for (int j=0; j<N; j++)
				valid_diag[i][j] <= 1'b0;
		for (int i=0; i<N; i++) begin
			a_boundary[i] <= 0;
			b_boundary[i] <= 0;
		end
	end else begin
		valid_diag[0][0] <= valid_in;
		for (int j=1; j<N; j++)
			valid_diag[0][j] <= valid_diag[0][j-1];
		for (int i=1; i<N; i++)
			valid_diag[i][0] <= valid_diag[i-1][0];
		for (int i=1; i<N; i++)
			for (int j=1; j<N; j++)
				valid_diag[i][j] <= valid_diag[i-1][j];

		for (int i=0; i<N; i++) begin
			a_boundary[i] <= a_row[i*DATA_WIDTH +: DATA_WIDTH];
			b_boundary[i] <= b_col[i*DATA_WIDTH +: DATA_WIDTH];
		end
	end
end

genvar i,j;

generate
	for (i=0;i < N;i++) begin : boundary_a
		assign a_wire[i][0] = a_boundary[i];
	end

	for (j=0;j < N;j++) begin : boundary_b
		assign b_wire[0][j] = b_boundary[j];
	end

	for (i=0;i < N;i++) begin
		for (j=0; j < N; j++) begin
			pe #(
				.DATA_WIDTH (DATA_WIDTH), 
				.ACCUM_WIDTH (ACCUM_WIDTH)
			) pe_inst (
				.clk (clk),
				.rst_n (rst_n),
				.a_in (a_wire[i][j]),
				.a_out (a_wire[i][j+1]),
				.b_in (b_wire[i][j]),
				.b_out (b_wire[i+1][j]),
				.valid_in (valid_diag[i][j]),
				.valid_out (),
				.accum (result_wire[i][j]),
				.clear (clear)
			);			
		end
	end


for (i=0;i < N;i++) begin : pack_row
	for (j=0; j < N; j++) begin : pack_col
		assign result[(i*N+j)*ACCUM_WIDTH +: ACCUM_WIDTH] = result_wire[i][j];
	end
end

endgenerate

assign valid_out = valid_diag[N-1][N-1];

endmodule

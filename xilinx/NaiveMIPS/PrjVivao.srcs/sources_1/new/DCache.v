`define NAIVE_DCACHE_FSM_IDLE				3'd0
`define NAIVE_DCACHE_FSM_WRITEBACK_FIRST	3'd1
`define NAIVE_DCACHE_FSM_WRITEBACK			3'd2
`define NAIVE_DCACHE_FSM_MEMREAD_FIRST		3'd3
`define NAIVE_DCACHE_FSM_MEMREAD			3'd4
`define NAIVE_DCACHE_FSM_WAIT_WRITE			3'd5

`define AHB_IDLE		2'b00
`define AHB_BUSY		2'b01
`define AHB_NONSEQ		2'b10
`define AHB_SEQ			2'b11

module DCache #(parameter
	CACHE_LINE_WIDTH = 6,
	TAG_WIDTH = 20
	`define INDEX_WIDTH (32 - CACHE_LINE_WIDTH - TAG_WIDTH)
	`define NUM_CACHE_LINES (2 ** `INDEX_WIDTH)
	`define OFFSET_WIDTH (CACHE_LINE_WIDTH-2)
) (
	// Clock and reset
	input  wire nrst,
	input  wire clk,

	// AHB Bus i/f
	output wire [31:0] AHB_haddr,
	output wire [2:0]  AHB_hburst,
	output wire [3:0]  AHB_hprot,
	input  wire [31:0] AHB_hrdata,
	output wire        AHB_hready_in,
	input  wire        AHB_hready_out,
	input  wire        AHB_hresp,
	output wire [2:0]  AHB_hsize,
	output reg  [1:0]  AHB_htrans,
	output wire [31:0] AHB_hwdata,
	output reg         AHB_hwrite,
	output reg         AHB_sel,

	// CPU i/f
	input  wire [31:0] dbus_addr,
	input  wire [3:0]  dbus_byteenable,
	input  wire        dbus_read,
	input  wire        dbus_write,
	input  wire        dbus_hitwriteback,
	input  wire        dbus_hitinvalidate,
	input  wire [31:0] dbus_wrdata,
	output wire [31:0] dbus_rddata,
	output wire        dbus_stall
);

	// Wires to cache lines
	wire [TAG_WIDTH-1:0]     rd_tag[`NUM_CACHE_LINES-1:0];
	wire [`OFFSET_WIDTH-1:0] rd_off;
	wire [31:0]              rd_data[`NUM_CACHE_LINES-1:0];
	wire                     rd_dirty[`NUM_CACHE_LINES-1:0];
	wire                     rd_valid[`NUM_CACHE_LINES-1:0];
	wire                     wr_write[`NUM_CACHE_LINES-1:0];
	reg  [TAG_WIDTH-1:0]     wr_tag;
	reg  [`OFFSET_WIDTH-1:0] wr_off;
	reg  [31:0]              wr_data;
	reg  [3:0]               wr_byte_enable;
	reg                      wr_dirty;
	reg                      wr_valid;

	// Storage
	genvar i;
	generate for (i = 0; i < `NUM_CACHE_LINES; i = i + 1) begin
	CacheLine #(
		.CACHE_LINE_WIDTH (CACHE_LINE_WIDTH),
		.TAG_WIDTH        (TAG_WIDTH)
	) lines (
		.nrst(nrst), .clk(clk),

		.rd_tag(rd_tag[i]), .rd_off(rd_off),
		.rd_data(rd_data[i]), .rd_dirty(rd_dirty[i]),
		.rd_valid(rd_valid[i]),

		.wr_write(wr_write[i]),
		.wr_tag(wr_tag), .wr_off(wr_off),
		.wr_data(wr_data), .wr_byte_enable(wr_byte_enable),
		.wr_dirty(wr_dirty), .wr_valid(wr_valid)
	);
	end endgenerate

	// FSM
	reg  [2:0] state;

	// Cache access tag, index and offset
	wire [TAG_WIDTH-1:0]     cache_addr_cpu_tag;
	reg  [TAG_WIDTH-1:0] cache_addr_mem_tag;
	wire [`INDEX_WIDTH-1:0]  cache_addr_idx;
	wire [`OFFSET_WIDTH-1:0] cache_addr_cpu_off;
	reg  [`OFFSET_WIDTH-1:0] cache_addr_access_off;
	wire [`OFFSET_WIDTH-1:0] cache_addr_mem_off = cache_addr_access_off + 4;
	wire [1:0]               cache_addr_dropoff;
	assign {
		cache_addr_cpu_tag,  cache_addr_idx,
		cache_addr_cpu_off,  cache_addr_dropoff
	} = dbus_addr;

	wire [`OFFSET_WIDTH-1:0] cache_addr_off = (
		state == `NAIVE_DCACHE_FSM_IDLE ?
		cache_addr_cpu_off : cache_addr_access_off
	);
	
	wire [`OFFSET_WIDTH-1:0] cache_end_off = 0 - 4;
	
	assign rd_off = cache_addr_off;

	// Status
	wire cl_valid = rd_valid[cache_addr_idx];
	wire cl_dirty = rd_dirty[cache_addr_idx];
    wire cl_hit   = rd_tag  [cache_addr_idx] == cache_addr_cpu_tag;
	wire [TAG_WIDTH-1:0]     cl_tag   = rd_tag  [cache_addr_idx];
	wire [31:0]              cl_data  = rd_data [cache_addr_idx];

	reg  write_cache;
	reg  [`INDEX_WIDTH-1:0] write_idx;
	generate for (i = 0; i < `NUM_CACHE_LINES; i = i + 1) begin
		assign wr_write[i] = write_cache ? i == write_idx : 1'b0;
	end endgenerate

	// AHB static wires
	assign AHB_hburst = 3'b011; // 4-beat incrementing burst
	assign AHB_hprot  = 4'b0011; // copied from ahb_adapter.v
	assign AHB_hready_in = AHB_hready_out;
	assign AHB_hsize  = 3'b110; // 512 bits i.e. 2^6 = 64 bytes
	
	// AHB access address
	assign AHB_haddr = {
		cache_addr_mem_tag,  cache_addr_idx,
		cache_addr_mem_off,  2'b0
	};
	assign AHB_hwdata = cl_data;

	// Logic
	wire need_writeback = cl_valid && cl_dirty && (
		(dbus_read  && ~cl_hit) || // rd
		(dbus_write && ~cl_hit) || // wr
		((dbus_hitwriteback || dbus_hitinvalidate) && cl_hit)
	);
	wire need_memread = (
		(dbus_read  && (~cl_valid || ~cl_hit)) || // rd
		(dbus_write && (~cl_valid || ~cl_hit)) // wr
	);

	// Outputs
	assign dbus_stall = (
		state != `NAIVE_DCACHE_FSM_IDLE ||
		need_writeback || need_memread
	);
	assign dbus_rddata = (!dbus_stall) ? cl_data : 0;

	// FSM controller
	always @(posedge clk, negedge nrst) begin
		if (~nrst) begin
			AHB_htrans <= `AHB_IDLE;
			AHB_hwrite <= 1'b0;
			AHB_sel <= 1'b0;
			
			write_cache <= 1'b0;
			cache_addr_access_off <= 1'b0;
			cache_addr_mem_tag <= 0;
			wr_valid <= 1'b0;
            wr_dirty <= 1'b0;
            wr_off <= 0;
            write_idx <= 0;
            wr_tag <= 0;
            wr_byte_enable <= 4'b0;
			wr_data <= 0;
			
			state <= `NAIVE_DCACHE_FSM_IDLE;
		end else begin
			case (state)
				`NAIVE_DCACHE_FSM_IDLE: begin
					if (need_writeback) begin
						state <= `NAIVE_DCACHE_FSM_WRITEBACK_FIRST;
						cache_addr_mem_tag <= cl_tag;
						cache_addr_access_off <= 0 - 4;
						AHB_htrans <= `AHB_NONSEQ;
						AHB_hwrite <= 1'b1;
						AHB_sel <= 1'b1;
						
					end else if (need_memread) begin
						state <= `NAIVE_DCACHE_FSM_MEMREAD_FIRST;
						cache_addr_mem_tag <= cache_addr_cpu_tag;
						cache_addr_access_off <= 0 - 4;
						AHB_htrans <= `AHB_NONSEQ;
						AHB_hwrite <= 1'b0;
						AHB_sel <= 1'b1;
						
					end else if (dbus_write) begin
						write_cache <= 1'b1;
						cache_addr_access_off <= cache_addr_cpu_off;
						wr_valid <= cl_valid;
						wr_dirty <= 1'b1;
                        wr_off <= cache_addr_off;
                        write_idx <= cache_addr_idx;
						wr_tag   <= cl_tag;
						wr_byte_enable <= dbus_byteenable;
						wr_data  <= dbus_wrdata;
						state <= `NAIVE_DCACHE_FSM_WAIT_WRITE;
						
					end else if (dbus_hitinvalidate) begin
						write_cache <= 1'b1;
						cache_addr_access_off <= cache_addr_cpu_off;
						wr_valid <= 1'b0;
						wr_dirty <= 1'b0;
						wr_off <= cache_addr_off;
                        write_idx <= cache_addr_idx;
						wr_tag   <= cl_tag;
						wr_byte_enable <= 4'b1111;
						wr_data  <= 0;
						state <= `NAIVE_DCACHE_FSM_WAIT_WRITE;
						
					end
					// if dbus_read data on dbus_rddata
					// if dbus_hitwriteback not need_writeback or finished
				end

				`NAIVE_DCACHE_FSM_WRITEBACK_FIRST: begin
					if (AHB_hready_out == 1'b1) begin
						cache_addr_access_off <= cache_addr_access_off + 4;
						AHB_htrans <= `AHB_SEQ;
						state <= `NAIVE_DCACHE_FSM_WRITEBACK;
					end
				end

				`NAIVE_DCACHE_FSM_WRITEBACK: begin
					if (AHB_hready_out == 1'b1) begin
						if (cache_addr_mem_off == 0) begin
							AHB_sel <= 1'b0;
							
							// finished writing of last word, cleanup dirty
							write_cache = 1'b1;
							wr_valid <= cl_valid;
							wr_dirty <= 0;
                            wr_off <= cache_addr_off;
                            write_idx <= cache_addr_idx;
							wr_tag <= cl_tag;
							wr_byte_enable <= 4'b0; // don't touch data
							state <= `NAIVE_DCACHE_FSM_WAIT_WRITE;

						end else begin
							if (cache_addr_mem_off == cache_end_off) begin
								// writing of last word ack
								AHB_htrans <= `AHB_IDLE;
								AHB_hwrite <= 1'b0;
							end
							cache_addr_access_off <= cache_addr_access_off + 4;
						end
					end
				end

				`NAIVE_DCACHE_FSM_MEMREAD_FIRST: begin
					if (AHB_hready_out == 1'b1) begin
						cache_addr_access_off <= cache_addr_access_off + 4;
						AHB_htrans <= `AHB_SEQ;
						// ignore first hrdata
						state <= `NAIVE_DCACHE_FSM_MEMREAD;
					end
				end

				`NAIVE_DCACHE_FSM_MEMREAD: begin
					if (AHB_hready_out == 1'b1) begin
						write_cache <= 1'b1;
						wr_dirty <= 1'b0;
                        wr_off <= cache_addr_off;
                        write_idx <= cache_addr_idx;
						wr_tag <= cache_addr_mem_tag;
						wr_byte_enable <= 4'b1111;
						wr_data <= AHB_hrdata;
						
						if (cache_addr_mem_off == 0) begin
							AHB_sel <= 1'b0;
							
							// finished reading cache, validate cacheline
							wr_valid <= 1'b1;
							state <= `NAIVE_DCACHE_FSM_WAIT_WRITE;
							
						end else begin
							if (cache_addr_mem_off == cache_end_off) begin
								// reading of last word ack
								AHB_htrans <= `AHB_IDLE;
							end
							wr_valid <= 1'b0;
							cache_addr_access_off <= cache_addr_access_off + 4;
						end

					end else begin
						write_cache <= 1'b0;
					end
				end
				
				`NAIVE_DCACHE_FSM_WAIT_WRITE: begin
					write_cache <= 1'b0;  // finished register writing
					state <= `NAIVE_DCACHE_FSM_IDLE;
				end

				default: begin
					state <= `NAIVE_DCACHE_FSM_IDLE;
				end
			endcase
		end
	end

endmodule
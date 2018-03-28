# EE480-Assignment-3
#
// basic sizes of things
`define WORD	[15:0]
`define Op	[15:12]
`define Dr	[11:8]
`define Sr	[7:4]
`define Tr	[3:0]
`define Immed	[7:0]
`define STATE	[7:0]

// opcode values, also state numbers
`define Onoarg	8'd0
`define	Xtrap	4'd0
`define	Xret	4'd1
`define	Xpushen	4'd2
`define	Xpopen	4'd4
`define	Xallen	4'd8
`define Ocont	8'd1
`define	Xcall	4'd0
`define	Xjump	4'd1
`define	Xjumpf	4'd3
`define Otwoarg	8'd2
`define	Xlnot	4'd0
`define	Xneg	4'd1
`define	Xleft	4'd2
`define	Xright	4'd3
`define	Xgor	4'd4
`define	Xload	4'd8
`define	Xstore	4'd9
`define Oadd	8'd4
`define Oslt	8'd5
`define Osra	8'd6
`define Omul	8'd7
`define Oand	8'd8
`define Oor	8'd9
`define Oxor	8'd10
`define Osll	8'd11
`define Oli8	8'd12
`define Olu8	8'd13

// state numbers only
`define Start	8'b11111111
`define Decode	8'd11111110

module processor(halt, reset, clk);
output reg halt;
input reset, clk;

reg `WORD regfile [15:0];
reg `WORD inst [65535:0];
reg `WORD data [65535:0];
reg `WORD pc, ir, addr;
reg `STATE s;
reg [31:0] en;
reg [63:0] retaddr;

always @(reset) begin
  halt = 0;
  pc = 0;
  s = `Start;
  regfile[0] = 0; // zero
  regfile[1] = 0; // IPROC
  regfile[2] = 1; // NPROC
  en = -1; // all 1s
  inst[0] = { `Oadd, 4'd6, 4'd2, 4'd2 };
  inst[1] = { `Onoarg, 4'd0, 4'd0, `Xtrap };
end

always @(posedge clk) begin
  case (s)
    `Start: begin ir <= inst[pc]; pc <= pc + 1; s <= `Decode; end
    `Decode: begin
	     s[3:0] <= ir `Op;
	     case (ir `Op)
		     `Onoarg, `Ocont, `Otwoarg:	s[7:4] <= (ir `Tr);
        	     default:			s[7:4] <= 0;
	     endcase
	     if ((ir `Op) == `Ocont) begin addr <= inst[pc]; pc <= pc + 1; end
	     end
    {`Xret,`Onoarg}:	begin pc <= retaddr[15:0]; retaddr <= {retaddr[63:48], retaddr[63:16]}; s <= `Start; end
    {`Xpushen,`Onoarg}:	begin en <= {en[30:0], en[0]}; s <= `Start; end
    {`Xpopen,`Onoarg}:	begin en <= {en[31], en[31:1]}; s <= `Start; end
    {`Xallen,`Onoarg}:	begin en <= {en[31:1], 1'b1}; s <= `Start; end
    {`Xcall,`Ocont}:	begin retaddr <= {retaddr[47:0], pc}; pc <= addr; s <= `Start; end
    {`Xjump,`Ocont}:	begin pc <= addr; s <= `Start; end
    {`Xjumpf,`Ocont}:	begin if (regfile[ir `Dr] == 0) begin en[0] <= 0; pc <= addr; end s <= `Start; end
    {`Xlnot,`Otwoarg}:	begin regfile[ir `Dr] <= !regfile[ir `Sr]; s <= `Start; end
    {`Xneg,`Otwoarg}:	begin regfile[ir `Dr] <= 0 - regfile[ir `Sr]; s <= `Start; end
    {`Xleft,`Otwoarg}, {`Xright,`Otwoarg}, {`Xgor,`Otwoarg}:
			begin regfile[ir `Dr] <= regfile[ir `Sr]; s <= `Start; end
    {`Xload,`Otwoarg}:	begin regfile[ir `Dr] <= data[regfile[ir `Sr]]; s <= `Start; end
    {`Xstore,`Otwoarg}:	begin data[regfile[ir `Sr]] <= regfile[ir `Dr]; s <= `Start; end
    {`Oadd}:		begin regfile[ir `Dr] <= regfile[ir `Sr] + regfile[ir `Tr]; s <= `Start; end
    {`Oslt}:		begin regfile[ir `Dr] <= (regfile[ir `Sr] < regfile[ir `Tr]); s <= `Start; end
    {`Osra}:		begin regfile[ir `Dr] <= regfile[ir `Sr] >> regfile[ir `Tr][3:0]; s <= `Start; end
    {`Omul}:		begin regfile[ir `Dr] <= regfile[ir `Sr] * regfile[ir `Tr]; s <= `Start; end
    {`Oand}:		begin regfile[ir `Dr] <= regfile[ir `Sr] & regfile[ir `Tr]; s <= `Start; end
    {`Oor}:		begin regfile[ir `Dr] <= regfile[ir `Sr] | regfile[ir `Tr]; s <= `Start; end
    {`Oxor}:		begin regfile[ir `Dr] <= regfile[ir `Sr] ^ regfile[ir `Tr]; s <= `Start; end
    {`Osll}:		begin regfile[ir `Dr] <= regfile[ir `Sr] << regfile[ir `Tr][3:0]; s <= `Start; end
    {`Oli8}:		begin regfile[ir `Dr] <= {{8{ir[7]}}, (ir `Immed)}; s <= `Start; end
    {`Olu8}:		begin regfile[ir `Dr] <= {(ir `Immed), regfile[ir `Dr][7:0]}; s <= `Start; end

    default: begin halt <= 1; end  // includes trap
  endcase
$display(regfile[6]);
end
endmodule

module bench;
reg reset = 1;
reg clk = 0;
wire done;
processor PE(done, reset, clk);
initial begin
  $dumpfile;
  $dumpvars(0, PE);
  #10 reset = 0;
  while (done == 0) begin
    #10 clk = 1;
    #10 clk = 0;
  end
 $finish;
end
endmodule


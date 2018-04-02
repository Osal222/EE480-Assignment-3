//These need to be checked and corrected
`define WORD          [15:0]
`define OPCode		[15:12]
`define Dest		[11:8]
`define Src           [7:4]
`define Alt           [3:0]
`define Imm           [7:0]
`define EN            [31:0]
`define STATE         [3:0]
`define OP            [5:0]

// This stuff should be fine
`define REGSIZE        [15:0]
`define MEMSIZE        [65535:0]
`define RETADDR        [63:0]
`define REGNAME        [3:0]
`define ESTACKSIZE     [31:0]
`define CSTACKSIZE     [63:0]

// 4bit opcodes 
`define OPAdd 4'b0000
`define OPAnd 4'b0001
`define OPMul 4'b0010
`define OPOr 4'b0011
`define OPSll		4'b0100
`define OPSlt		4'b0101
`define OPSra		4'b0110
`define OPXor		4'b0111
`define OPGor         4'b1000
`define OPLeft        4'b1001
`define OPRight       4'b1010
`define OPLnot        4'b1011
`define OPNeg         4'b1100
`define OPLI8		4'b1101
`define OPLU8		4'b1110
`define OP8Reg		4'b1111

//extended code
`define OPLoad 5'b10000
`define OPStore 5'b10001
`define OPAllen		5'b10010
`define OPPopen		5'b10011
`define OPPushen 	5'b10100
`define OPRet		5'b10101
`define OPNop		5'b10110
`define OPTrap		5'b10111
`define OPCall		5'b11000
`define OPJump		5'b11001
`define OPJumpf		5'b11010

//SRC values 
`define SRCLoad 4'b0000
`define SRCStore 4'b0001
`define SRCAllen 4'b0010
`define SRCPopen 4'b0011
`define SRCPushen 4'b0100
`define SRCRet 4'b0101
`define SRCNop 4'b0110
`define SRCTrap 4'b0111
`define SRCCall 4'b1000
`define SRCJump 4'b1001
`define SRCJumpf 4'b1010


//Not sure if this works, this is for the ext. op

// Decoder is not finished
/////////////////////////////////////////////////////////////////////
module decode(out, regd, in, ireg);
output reg `OPCode out;
output reg `REGNAME regd;

input wire `OP in;
input `WORD ireg;

always @(in, ireg) begin
	if((in == `OPJumpf) || (in == `OPJump) || (in == `OPCall)) begin
		out = `OPNop;  // 2nd word of li becomes nop
		regd = 0;           // No writing will occur
	end else begin
		case (ir `OPCode)
			`OP8Reg:begin
			regd=0;
			case (ir ‘Dest)
				`SRCLoad: opout = `OPLoad;
				`SRCStore: opout = `OPStore;
				`SRCAllen: opout = `OPAllen;
				`SRCPopen: opout = `OPPopen;
				`SRCPushen: opout = `OPPushen;
				`SRCRet: opout = `OPRet;
				`SRCNop: opout = `OPNop;
				`SRCTrap: opout = `OPTrap;
				`SRCCall: opout = `OPCall;
				`SRCJump: opout = `OPJump;
				`SRCJumpf: opout = `OPJumpf;
    			endcase
      	end
      	`OPStore: begin opout = ir `OPCode; regdst <= 0; end
           default: begin opout = ir `OPCode; regdst <= ir `Dest; end
    endcase
  end
end
endmodule



				
			`
/////////////////////////////////////////////////////////////////////



// ALU is finished for the most part
/////////////////////////////////////////////////////////////////////
module alu(Result, OPCode, Instuct1, Instruct2);
output reg `WORD Result;
input wire `OP opcode;
input wire `WORD Instruct1, Instruct2;

always @(opcode, Instruct1, Instruct2) begin
  case (opcode)
	`OPAdd:   begin result = Instruct1 + Instruct2; end
	`OPAnd:   begin result = Instruct1 & Instruct2; end
	`OPMul:   begin result = Instruct1 * Instruct2; end
	`OPOr:    begin result = Instruct1 | Instruct2; end
	`OPGor:   begin result = Instruct1; end 
	`OPXor:   begin result = Instruct1 ^ Instruct2; end
	`OPSll:   begin result = Instruct1 << (Instruct2 & 4'b1111); end 
	`OPSra:   begin result = Instruct1 >> (Instruct2 & 4'b1111); end
	`OPLnot:  begin result = !Instruct1; end
	`OPNeg:   begin result = ~Instruct1; end
	`OPSlt:   begin result = (Instruct1 < Instruct2)? 4'b1 : 4'b0;end
	`OPLeft:  begin result = Instruct1; end
	`OPRight: begin result = Instruct1; end
	default:  begin result = Instruct1; end
  endcase
end
endmodule
/////////////////////////////////////////////////////////////////////

// Still working on processor
/////////////////////////////////////////////////////////////////////
module processor(halt, reset, clk);
output reg halt;
input reset, clk;

reg  `WORD RegFile `REGSIZE;
reg  `WORD InstructMem `MEMSIZE;
reg  `WORD DataMem `MEMSIZE;
reg  `WORD NewPC, IReg, SrcVal, DstVal;
wire `OP DecOP;
wire `REGNAME RegDst;
wire `WORD ALUResult;
reg  `ESTACKSIZE en = 1;
reg  `CSTACKSIZE CallStack;
reg  `OPCode s0OP, s1OP, s2OP;
reg  `REGNAME s0Src, s0Dst, s0RegDst, s1RegDst, s2RegDst;
reg  `WORD PC;
reg  `WORD s1SrcVal, s1DstVal;
reg  `WORD s2Val;

always @(reset) begin
    halt = 0;
    pc = 0;
    s0OP = `OPNop;
    s1OP = `OPNop;
    s2OP = `OPNop;
    $readmemh0(RegFile);
    $readmemh1(InstructMem);
    $readmemh2(DataMem);
end

decode MyDecode(DecOP, RegDst, s0OP, IReg);
alu ALU(ALUResult, s1OP, s1SrcVal, s1DstVal);

always @(*) IReg = InstructMem[PC];

// new pc value
always @(*) begin 
    NewPC = ((s1OP == `OPJumpf) && (s1DstVal == 0)) ? s1SrcVal :
        (s1OP == `OPJump) ? s1SrcVal: ((s1OP == `OPCall) &&     
        (en[0] == 1)) ? s1SrcVal: ((s1OP == `OPRet) &&(en[0] == 1)) ?          
        CallStack[15:0] : (PC + 1); 
    
    if(s1OP == `OPJumpf && s1DstVal == 0) begin
        en[0] = ~en[0];
    end
    if(s1OP == `OPCall && en[0] == 1) begin
        CallStack = CallStack[47:0], PC;
    end
    if(s1OP == `OPRet && en[0] == 1) begin
        CallStack = CallStack[63:48], CallStack[63:16];
    end
end

// compute RR SrcVal, with value forwarding... also from 2nd word of li
always @(*) begin 
    if ((s0OP == `OPJump) || (s0OP == `OPJumpf) || (s0OP == `OPCall))     
        SrcVal = IReg; // catch immediate for li
    else SrcVal = ((s1RegDst && (s0Src == s1RegDst)) ? ALUResult :
        ((s2RegDst && (s0Src == s2RegDst)) ? s2Val :RegFile[s0Src]));
end

// compute RR DstVal, with value forwarding
always @(*) DstVal = ((s1RegDst && (s0Dst == s1RegDst)) ? ALUResult :
    ((s2RegDst && (s0Dst == s2RegDst)) ? s2Val : RegFile[s0Dst]));

// Instruction Fetch
always @(posedge clk) if (!halt) begin
    s0OP <= (DecOP == `OPTrap) ? `OPNop : DecOP;
    s0RegDst <= (DecOP == `OPTrap) ? 0 : RegDst;
    s0Src <= ir `Src;
    s0Dst <= ir `Dest;
    PC <= NewPC;
end

// Register Read
always @(posedge clk) if (!halt) begin
    s1OP <= s0OP;
    s1RegDst <= s0RegDst;
    s1SrcVal <= SrcVal;
    s1DstVal <= DstVal;
end

// ALU and data memory operations
always @(posedge clk) if (!halt) begin
    s2OP <= s1OP;
    s2RegDst <= s1regdst;
    s2Val <= ((s1OP == `OPLoad) ? DataMem[s1SrcVal] : ALUResult);
    if (s1OP == `OPStore) DataMem[s1SrcVal] <= s1DstVal;
    //////////if (s1op == `OPsys) halt <= 1;
end

// Register Write
always @(posedge clk) if (!halt) begin
    if (s2RegDst != 0) RegFile[s2RegDst] <= s2Val;
end
endmodule

/*
File     : divider_top.v 
Author   : Gandhi Puvvada
Revision  : 1.1, 2.0 (Nexys-3), 3.0 (Nexys-4)
Date : Feb 15, 2008, 10/14/08, 2/12/2012, 2/17/2020
*/

/*
A verlog top module for the 4-bit division by repetitive subtraction.
An example verilog design for the ee201L students.

 The program does the following:
 
 We set the 4-bit dividend (Xin) and the 4-bit divisor (Yin) 
 on Sw7-Sw4 and Sw3-Sw0 respectively. 
 The BtnL (Btn Left) is our Start button and BtnR (Btn Right) is our Ack button.
 The Ld3, Ld2, Ld1, Ld0 glow when BtnL, BtnU, BtnR, BtnD  are pressed respectively.
 The Ld4 glows when the Done signal is activated by the divider.
 Ld7, Ld6, Ld5 represent Initial (QI), Compute (QC) and Done (QD) states.
 The BtnC (the center button)  the Nexys 3 or Nexys 4 boards acts as the Reset button in this design.
 The right 4 digits (SSDs) from left to right display, the dividend, the divisor,
 the quotient, and the remainder.
 
 We did not add debouncing circuitry, nor single stepping circuitry
 in this rather simple-minded design. 

Here, we are deliberately using a very slow clock ( DIV_CLK[25]) so that 
we can see the quotient and remainder changing progressively. 
In the other design with debouncing and single stepping, we will use the 
full-speed clock.
*/
/*
 Make sure to use the ee354_top.xdc file containing pin info.
*/
module divider_top		(   
		MemOE, MemWR, RamCS, QuadSpiFlashCS, // Disable the three memory chips

        ClkPort,                           // the 100 MHz incoming clock signal
		
		BtnL, BtnU, BtnD, BtnR,            // the Left, Up, Down, and the Right buttons 		BtnL, BtnR,
		BtnC,                              // the center button (this is our reset in most of our designs)
		Sw7, Sw6, Sw5, Sw4, Sw3, Sw2, Sw1, Sw0, // 8 switches
		Ld7, Ld6, Ld5, Ld4, Ld3, Ld2, Ld1, Ld0, // 8 LEDs
		An3, An2, An1, An0,			       // 4 anodes
		An7, An6, An5, An4,                // another 4 anodes (we need to turn these unused SSDs off)
		Ca, Cb, Cc, Cd, Ce, Cf, Cg,        // 7 cathodes
		Dp                                 // Dot Point Cathode on SSDs
	  );
	 
								
	/*  INPUTS */
	// Clock & Reset I/O
	input		ClkPort;	
	// Project Specific Inputs
	input		BtnL, BtnU, BtnD, BtnR, BtnC;	
	input		Sw7, Sw6, Sw5, Sw4, Sw3, Sw2, Sw1, Sw0;
	
	
	/*  OUTPUTS */
	// Control signals on Memory chips 	(to disable them)
	output 	MemOE, MemWR, RamCS, QuadSpiFlashCS;
	// Project Specific Outputs
	// LEDs
	output 	Ld0, Ld1, Ld2, Ld3, Ld4, Ld5, Ld6, Ld7;
	// SSD Outputs
	output 	Cg, Cf, Ce, Cd, Cc, Cb, Ca, Dp;
	output 	An0, An1, An2, An3;	
	output  An4, An5, An6, An7; // extra four unused SSDs need to be turned off

	
	/*  LOCAL SIGNALS */
	wire		Reset, ClkPort;
	wire		board_clk, sys_clk;
	wire [1:0] 	ssdscan_clk;
	
	wire [3:0] 	Xin, Yin;
	wire [3:0] 	Quotient, Remainder;
	wire 		Start, Ack;
	wire 		Done, Qi, Qc, Qd;

// to produce divided clock
	reg [26:0]	DIV_CLK;
// SSD (Seven Segment Display)
	reg [3:0]	SSD;
	wire [3:0]	SSD3, SSD2, SSD1, SSD0;
	reg [7:0]  	SSD_CATHODES;
	
	
//------------	
// Disable the two memories so that they do not interfere with the rest of the design.
	assign {MemOE, MemWR, RamCS, QuadSpiFlashCS} = 4'b1111;
	
	
//------------
// CLOCK DIVISION

	// The clock division circuitary works like this:
	//
	// ClkPort ---> [BUFGP2] ---> board_clk
	// board_clk ---> [clock dividing counter] ---> DIV_CLK
	// DIV_CLK ---> [constant assignment] ---> sys_clk;
	
	// Instantiation of BUFGP is an old practice. The implementation tools provide an appropriate Global Buffer automatically.
	// BUFGP BUFGP1 (board_clk, ClkPort); 	
	assign board_clk = ClkPort;	


// As the ClkPort signal travels throughout our design,
// it is necessary to provide global routing to this signal. 
// The BUFGPs buffer these input ports and connect them to the global 
// routing resources in the FPGA.

	// BUFGP BUFGP2 (Reset, BtnC); In the case of Spartan 3E (on Nexys-2 board), we were using BUFGP to provide global routing for the reset signal. But Spartan 6 (on Nexys-3) does not allow this.
	assign Reset = BtnC;
	
//------------
	// Our clock is too fast (100MHz) for SSD scanning
	// create a series of slower "divided" clocks
	// each successive bit is 1/2 frequency
  always @(posedge board_clk, posedge Reset) 	
    begin							
        if (Reset)
		DIV_CLK <= 0;
        else
		DIV_CLK <= DIV_CLK + 1'b1;
    end
//------------	
	// pick a divided clock bit to assign to system clock
	// your decision should not be "too fast" or you will not see you state machine working
	assign	sys_clk = DIV_CLK[25]; // DIV_CLK[25] (~1.5Hz) = (100MHz / 2**26)
	// in future designs we will use the full speed clock

	//------------         

	assign Xin = {Sw7, Sw6, Sw5, Sw4};
	assign Yin = {Sw3, Sw2, Sw1, Sw0};
	assign Start = BtnL; assign Ack = BtnR;
						
	// instantiate the core divider design
	divider divider_1(.Xin(Xin), .Yin(Yin), .Start(Start), .Ack(Ack), .Clk(sys_clk), .Reset(Reset), 
				.Done(Done), .Quotient(Quotient), .Remainder(Remainder), .Qi(Qi), .Qc(Qc), .Qd(Qd) );

//------------
// OUTPUT: LEDS
	
	assign {Ld7, Ld6, Ld5, Ld4} = {Qi, Qc, Qd, Done};
	assign {Ld3, Ld2, Ld1, Ld0} = {Start, BtnU, Ack, BtnD}; 
	
//------------
// SSD (Seven Segment Display)
	// reg [3:0]	SSD;
	// wire [3:0]	SSD3, SSD2, SSD1, SSD0;
	
	//SSDs display Xin, Yin, Quotient, and Reminder  
	assign SSD3 = Xin;
	assign SSD2 = Yin;
	assign SSD1 = Quotient;
	assign SSD0 = Remainder;


	// need a scan clk for the seven segment display 
	
	// 100 MHz / 2^18 = 381.5 cycles/sec ==> frequency of DIV_CLK[17]
	// 100 MHz / 2^19 = 190.7 cycles/sec ==> frequency of DIV_CLK[18]
	// 100 MHz / 2^20 =  95.4 cycles/sec ==> frequency of DIV_CLK[19]
	
	// 381.5 cycles/sec (2.62 ms per digit) [which means all 4 digits are lit once every 10.5 ms (reciprocal of 95.4 cycles/sec)] works well.
	
	//                  --|  |--|  |--|  |--|  |--|  |--|  |--|  |--|  |   
    //                    |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | 
	//  DIV_CLK[17]       |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|
	//
	//               -----|     |-----|     |-----|     |-----|     |
    //                    |  0  |  1  |  0  |  1  |     |     |     |     
	//  DIV_CLK[18]       |_____|     |_____|     |_____|     |_____|
	//
	//         -----------|           |-----------|           |
    //                    |  0     0  |  1     1  |           |           
	//  DIV_CLK[19]       |___________|           |___________|
	//

	assign ssdscan_clk = DIV_CLK[19:18];
	assign An0	= !(~(ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 00
	assign An1	= !(~(ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 01
	assign An2	=  !((ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 10
	assign An3	=  !((ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 11
	// Turn off another 4 anodes
	assign {An7, An6, An5, An4} = 4'b1111;
	
	always @ (ssdscan_clk, SSD0, SSD1, SSD2, SSD3)
	begin : SSD_SCAN_OUT
		case (ssdscan_clk) 
				  2'b00: SSD = SSD0;
				  2'b01: SSD = SSD1;
				  2'b10: SSD = SSD2;
				  2'b11: SSD = SSD3;
		endcase 
	end

	// Following is Hex-to-SSD conversion
	always @ (SSD) 
	begin : HEX_TO_SSD
		case (SSD) // in this solution file the dot points are made to glow by making Dp = 0
		    //                                                                abcdefg,Dp
			4'b0000: SSD_CATHODES = 8'b00000010; // 0
			4'b0001: SSD_CATHODES = 8'b10011110; // 1
			4'b0010: SSD_CATHODES = 8'b00100100; // 2
			4'b0011: SSD_CATHODES = 8'b00001100; // 3
			4'b0100: SSD_CATHODES = 8'b10011000; // 4
			4'b0101: SSD_CATHODES = 8'b01001000; // 5
			4'b0110: SSD_CATHODES = 8'b01000000; // 6
			4'b0111: SSD_CATHODES = 8'b00011110; // 7
			4'b1000: SSD_CATHODES = 8'b00000000; // 8
			4'b1001: SSD_CATHODES = 8'b00001000; // 9
			4'b1010: SSD_CATHODES = 8'b00010000; // A
			4'b1011: SSD_CATHODES = 8'b11000000; // B
			4'b1100: SSD_CATHODES = 8'b01100010; // C
			4'b1101: SSD_CATHODES = 8'b10000100; // D
			4'b1110: SSD_CATHODES = 8'b01100000; // E
			4'b1111: SSD_CATHODES = 8'b01110000; // F    
			default: SSD_CATHODES = 8'bXXXXXXXX; // default is not needed as we covered all cases
		endcase
	end	
	
	// reg [7:0]  SSD_CATHODES;
	assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp} = {SSD_CATHODES};
	
endmodule

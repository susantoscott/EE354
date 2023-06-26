//////////////////////////////////////////////////////////////////////////////////
// Author:			Shideh Shahidi, Bilal Zafar, Gandhi Puvvada
// Create Date:   02/25/08, 10/13/08
// File Name:		ee201_GCD_tb.v 
// Description: 
//
//
// Revision: 		2.1
// Additional Comments:  
// 10/13/2008 Clock Enable (CEN) has been added by Gandhi
// 3/1/2010 Signal names are changed in line with the divider_verilog design
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module ee354_GCD_CEN_part3_tb_v;

	// Inputs
	reg Clk, CEN;
	reg Reset;
	reg Start;
	reg Ack;
	reg [7:0] Ain;
	reg [7:0] Bin;
	integer fd;
	integer A_count;
	integer B_count;

	// Outputs
	wire [7:0] A, B, AB_GCD, i_count;
	wire q_I;
	wire q_Sub;
	wire q_Mult;
	wire q_Done;
	reg [6*8:0] state_string; // 6-character string for symbolic display of state
	reg [40*8:1] str;
	
	// Instantiate the Unit Under Test (UUT)
	ee354_GCD uut (
		.Clk(Clk), 
		.CEN(CEN),
		.Reset(Reset), 
		.Start(Start), 
		.Ack(Ack), 
		.Ain(Ain), 
		.Bin(Bin), 
		.A(A),
		.B(B),
		.AB_GCD(AB_GCD), 
		.i_count(i_count),
		.q_I(q_I), 
		.q_Sub(q_Sub), 
		.q_Mult(q_Mult), 
		.q_Done(q_Done)
	);
		
		initial begin
			begin: CLOCK_GENERATOR
				Clk = 0;
				forever begin
					#5 Clk = ~ Clk;
				end
			end
		end
		initial begin
			#0 Reset = 0;
			#20 Reset = 1;
			#20 Reset = 0;
		end
		initial begin
			fd = $fopen("ee354_gcd_Part3_output.txt", "w");
		end
		
		/*-------- clock counter --------*/
		integer clk_cnt, start_clk_cnt, clocks_taken;
		always @(posedge Clk) begin
			if(Reset) begin
				clk_cnt = 0;
			end
			else begin
				clk_cnt = clk_cnt + 1;
			end
		end
		initial begin
		// Initialize Inputs
		CEN = 1; // ****** in Part 2 ******
				 // Here, in Part 1, we are enabling clock permanently by making CEN a '1' constantly.
				 // In Part 2, your TOP design provides single-stepping through SCEN control.
				 // We are not planning to write a testbench for the part 2 design. However, if we were 
				 // to write one, we will remove this line, and make CEN enabled and disabled to test 
				 // single stepping.
				 // One of the things you make sure in your core design (DUT) is that when state 
				 // transitions are stopped by making CEN = 0,
				 // the data transformations are also stopped.
		Start = 0;
		Ack = 0;
		Ain = 0;
		Bin = 0;
		start_clk_cnt = 0;
		clocks_taken = 0;


		// Wait 100 ns for global reset to finish
		#103;

		for (A_count = 2; A_count < 64; A_count = A_count + 1) begin
			for (B_count = 2; B_count < 64; B_count = B_count + 1) begin
				APPLY_STIMULUS(A_count, B_count);
			end
		end

		$fclose(fd);
		$display("\nWrote to ee354_gcd_Part3_output.txt!");

	end
	
	always @(*)
		begin
			case ({q_I, q_Sub, q_Mult, q_Done})    // Note the concatenation operator {}
				4'b1000: state_string = "q_I   ";  // ****** TODO ******
				4'b0100: state_string = "q_Sub ";  // Fill-in the three lines
				4'b0010: state_string = "q_Mult";
				4'b0001: state_string = "q_Done";			
			endcase
		end
		
	task APPLY_STIMULUS;
		input [7:0] Ain_value;
		input [7:0] Bin_value;
		begin
			Ain = Ain_value;
			Bin = Bin_value;
			@(posedge Clk);									
			
			// generate a Start pulse
			Start = 1;
			@(posedge Clk);	
			Start = 0;

			wait(q_Sub);
			start_clk_cnt = clk_cnt;
				
			wait(q_Done);
			clocks_taken = clk_cnt - start_clk_cnt;

			// generate and Ack pulse
			#5;
			Ack = 1;
			@(posedge Clk);		
			Ack = 0;
			
			$display("Ain: %d Bin: %d, GCD: %d", Ain, Bin, AB_GCD);
			$display("It took %d clock(s) to compute the GCD", clocks_taken);
			
			str = "\n";
			$sformat(str, "%s\tAin: %d Bin: %d, GCD: %d", str, Ain, Bin, AB_GCD);
			$fdisplay(fd, "%s", str);
			
			#20;
		end
	endtask
 
      
endmodule


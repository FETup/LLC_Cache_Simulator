import cache_define ::*;


module cache( input [31:0] address, input [4:0]  command );


//logic [5:0] 	Byte_Select [3:0][1:0];
//logic [1:0] 	Index_Bits  [3:0];
logic [23:0]    Tag_Array    [3:0][1:0];

logic [5:0] 	Byte_Select;
logic [1:0] 	Index_Bits;
logic [23:0]    Tag_Bits;

int i_point,b_point;
int status;

//assign Tag_Array[2][0] = 24'b000100000000000110011101;

assign Byte_Select = address[5:0];
assign Index_Bits  = address[7:6];
assign Tag_Bits    = address[31:8];

initial begin

for (i_point = 0; i_point< 5 ; i_point++) begin

	for(b_point = 0;b_point < 3; b_point++) begin

		Tag_Array[i_point][b_point] = 24'b0;
        end
end
end


always@(command or address) begin

	case(command)

		0: begin

                        $display("READDD COMMMANDDD");

			

			for(b_point = 0; b_point < 3; b_point++) begin
				
				if(Tag_Array[Index_Bits][b_point] == Tag_Bits) begin

					$display("It's a FUCKIN HIIITTT!");
                                        $display("Tag = %b ,Index_bits = %b, Tag_bits = %b" ,Tag_Array[Index_Bits][b_point], Index_Bits, Tag_Bits);
                                end
                                else 
					status = 1;
					  
                        end
			
                         if(status) begin
				status = 0;
				$display("It's a Miss :( ");

				for(b_point = 0; b_point < 2; b_point++) begin
				
					if(Tag_Array[Index_Bits][b_point] == 24'b0) begin

						Tag_Array[Index_Bits][b_point] = Tag_Bits;  //Saving to every empty location in set

                                	end 
                         	
			
			 	end
		
			end 

		end
		default:
			$display("BHOKAT GELA");
			
			
	endcase


end


endmodule	
import cache_define ::*;


module cache( input [31:0] address, input [4:0]  command );

////////////CACHE///////////////
//logic [5:0] 	Byte_Select [3:0][1:0];
//logic [1:0] 	Index_Bits  [3:0];
logic [23:0]    Tag_Array    [3:0][3:0];
logic [2:0]     LRU_Array    [3:0];

//////ADDRESS BITS/////////
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

	for(b_point = 0;b_point < 4; b_point++) begin

		Tag_Array[i_point][b_point] = 24'b0;
        end
end
end


always@(command or address) begin

$display("%d %d %d", index, byte_bits, tag_bits); 
	case(command)

		0: begin

                        $display("READDD COMMMANDDD");
                         status = 0;
			

			for(b_point = 0; b_point < 4; b_point++) begin
				
				if(Tag_Array[Index_Bits][b_point] == Tag_Bits) begin

					$display("It's a FUCKIN HITT!");
					

					case(b_point) 
					
						0:  LRU_Array[Index_Bits][1:0] =  2'b00;
                        			1:  LRU_Array[Index_Bits][1:0] =  2'b10;
						2:begin  
							LRU_Array[Index_Bits][0] =  1'b1;
                                                        LRU_Array[Index_Bits][2] =  1'b0;
                                                  end
                                                3:begin  
							LRU_Array[Index_Bits][0] =  1'b1;
                                                        LRU_Array[Index_Bits][2] =  1'b1;
                                                  end
						
                    			endcase
                    			 					
					$display("Tag = %b ,Index_bits = %b, Tag_bits = %b,LRU %b" ,Tag_Array[Index_Bits][b_point], Index_Bits, Tag_Bits,LRU_Array[Index_Bits]);
					status = 1;
                                        break;
                
				end
				
			end 

			if(status != 1) 
				status = 2;
					  
				
			if(status == 2) begin
				
				status = 0;
				$display("It's a Miss :( ");

				for(b_point = 0; b_point < 4; b_point++) begin
				
					if(Tag_Array[Index_Bits][b_point] == 24'b0) begin

						Tag_Array[Index_Bits][b_point] = Tag_Bits;  //Saving to every empty location in set
                                                
						break;

					end 
                         	
			       $display("%d",Tag_Array[Index_Bits][b_point]);
			       end
		
			

		       end
                      
		end
		default:
			$display("Jhav Jhav Nusti");
			
			
	endcase


end


endmodule	
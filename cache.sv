import cache_define ::*;


module cache( input [31:0] address, input [4:0]  command );

////////////CACHE///////////////

logic [(TAG_BITS - 1) :0]     Tag_Array    [(INDEX - 1):0][(ASSOC-1):0];
logic [(LRU_BITS - 1) :0]     LRU_Array    [(INDEX - 1) : 0 ];

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
      
        LRU_Array[i_point] = 3'b0;
	for(b_point = 0;b_point < 5; b_point++) begin

		Tag_Array[i_point][b_point] = 24'b0;
        end
end



end


always@(command or address) begin

	case(command)

		0: begin

                	$display("/\/\/READ COMMAND/\/\/");
                        status = 0;
			
		        LRU_access;		
			 
			if(status != HIT) 
				status = MISS;
					  			
			if(status == MISS) begin
				
				LRU_replacement;
			
		        end                    
		end
		default:
			$display("Default");
			
	endcase


end

task LRU_access;


	for(b_point = 0; b_point < 4; b_point++) begin
				
		if(Tag_Array[Index_Bits][b_point] == Tag_Bits) begin

			$display("Cache Hit!");
					

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
                    			 					
			$display("Tag = %h ,Index_bits = %b, Tag_bits = %b,LRU %b" ,address, Index_Bits, Tag_Bits,LRU_Array[Index_Bits]);
			status = HIT;
                        break;
                
		end
	end


endtask


task LRU_replacement;


	status = 0;
	$display("Cache Miss");
        $display("%b",Index_Bits);

	//for(b_point = 0; b_point < 5; b_point++) begin
				
	//if(Tag_Array[Index_Bits][b_point] == 24'b0) begin

         casez(LRU_Array[Index_Bits])

         3'b0?0: begin
		Tag_Array[Index_Bits][3] = Tag_Bits;
                LRU_Array[Index_Bits][0] =  1'b1;
                LRU_Array[Index_Bits][2] =  1'b1;
	 end

	3'b1?0: begin
		Tag_Array[Index_Bits][2] = Tag_Bits;
		LRU_Array[Index_Bits][0] =  1'b1;
                LRU_Array[Index_Bits][2] =  1'b0;
	 end
         
        3'b?01: begin
		Tag_Array[Index_Bits][1] = Tag_Bits;
                LRU_Array[Index_Bits][1:0] =  2'b10;

         end
	 3'b?11: begin
		Tag_Array[Index_Bits][0] = Tag_Bits;
                LRU_Array[Index_Bits][1:0] =  2'b00;

         end

         endcase

          
		
                         	
			       $display("LRU = %b Tag array = %p",LRU_Array[Index_Bits],Tag_Array[Index_Bits]);
	//end
		
endtask

endmodule	
import cache_define ::*;


module cache (input logic [31:0] address, input logic [3:0]  command, input int w_mode, input int w_debug, input int w_eof);

////////////CACHE///////////////

logic [(TAG_BITS    - 1) : 0]     Tag_Array    [(INDEX - 1) : 0][(ASSOC-1):0];
logic [(LRU_BITS    - 1) : 0]     LRU_Array    [(INDEX - 1) : 0 ];
logic [(STATE_WIDTH - 1) : 0]     State_Array  [(INDEX - 1) : 0][(ASSOC-1): 0];  

//////ADDRESS BITS/////////
logic [(BYTE_BITS   - 1) : 0] 	 Byte_Select;
logic [(INDEX_BITS  - 1) : 0] 	 Index_Bits;
logic [(TAG_BITS    - 1) : 0]    Tag_Bits;
logic [(ASSOC_BITS  - 1) : 0]    Way_Index; 
logic [TAG_BITS + INDEX_BITS + BYTE_BITS - 1:0] evict_address;

/////LOG//////
logic [TAG_BITS + INDEX_BITS + BYTE_BITS - 1 : 0] command_count;
logic [TAG_BITS + INDEX_BITS + BYTE_BITS - 1 : 0] hit_count;
logic [TAG_BITS + INDEX_BITS + BYTE_BITS - 1 : 0] cpu_req;
logic [TAG_BITS + INDEX_BITS + BYTE_BITS - 1 : 0] cpu_rd;
logic [TAG_BITS + INDEX_BITS + BYTE_BITS - 1 : 0] cpu_wr;

snoop_result_t putSnoop_Result;
snoop_result_t Snoop_Result;
busopt_t       bus_check;

int indx_itr, way_itr, status;
logic [3:0] cmd;

//assign Tag_Array[2][0] = 24'b000100000000000110011101;

assign Byte_Select = address[(BYTE_BITS - 1)                  :                      0];
assign Index_Bits  = address[(INDEX_BITS + BYTE_BITS-1)       :            (BYTE_BITS)];
assign Tag_Bits    = address[(TAG_BITS+INDEX_BITS+BYTE_BITS-1):(INDEX_BITS+ BYTE_BITS)];
//assign Snoop_Result = address[1:0];

initial begin
	command_count = 0;
	hit_count     = 0;
	cpu_req       = 0;
	cpu_rd        = 0;
	cpu_wr        = 0;	
	if ( w_debug == DEBUG_MODE )
		$display("Index %d, Index Width = %d, Tag width = %d, Byte Width = %d",INDEX,INDEX_BITS,TAG_BITS,BYTE_BITS);

	for (indx_itr = 0; indx_itr < INDEX; indx_itr++) begin
		LRU_Array[indx_itr] = 7'b0000000;
		
		for (way_itr = 0;way_itr < ASSOC; way_itr++) begin
			Tag_Array[indx_itr][way_itr]   = 'z;
			State_Array[indx_itr][way_itr] = I;
		end
	end
end

always@(posedge w_eof) begin

	$display("Total CPU reads    = %32d", cpu_rd);
	$display("Total CPU writes   = %32d", cpu_wr);
	$display("Total Cache hits   = %32d", hit_count);
	$display("Total Cache Miss   = %32d", cpu_req - hit_count);
	$display("Cache Hit Ratio    = %32f", hit_count / (cpu_req * 1.0));
	$display("Cache Hit percentage: = %32f", (hit_count * 100.0)/ cpu_req);

end

always@(command or address) begin
	command_count = command_count + 1;
	cmd           = command;
	
	case(command)
	DATA_READ:	
			begin

			if ( w_debug == DEBUG_MODE )
            			$display("\n------READ COMMAND------");

			cpu_req	 = cpu_req + 1;
			cpu_rd	 = cpu_rd  + 1;
           		status   = 0;
			LRU_access;		
			 
			if ( status != CACHE_HIT ) 
				status = CACHE_MISS;
			else begin
				status    = CACHE_HIT;
				hit_count = hit_count + 1;
			end
					  			
			if ( status == CACHE_MISS )
				LRU_replacement;
			
			cmd = CPU_READ;
          		MESI;
			if ( w_debug == DEBUG_MODE )
				$display("++++++++++++++++++++++++++++++++++++++++++++++++++++++++");              
		    	end

	DATA_WRITE: 
			begin

			if ( w_debug == DEBUG_MODE )
            			$display("\n------WRITE COMMAND------");

			cpu_req = cpu_req + 1;
			cpu_wr	 = cpu_wr  + 1;
           		status  = 0;
			LRU_access;		
			 
			if ( status != CACHE_HIT ) 
				status = CACHE_MISS;
			else begin
				status    = CACHE_HIT;
				hit_count = hit_count + 1;
			end
					  			
			if ( status == CACHE_MISS ) begin
				LRU_replacement;
		    	end   
			
			cmd = CPU_WRITE;
            		MESI;

			if ( w_debug == DEBUG_MODE )
				$display("++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
              
		    	end

	INST_READ: 
			begin

			if ( w_debug == DEBUG_MODE )
            			$display("\n------READ INSTRUCTION COMMAND------");	
		
			cpu_req = cpu_req + 1;
			cpu_rd	 = cpu_rd  + 1;
           		status  = 0;
			LRU_access;		
			 
			if ( status != CACHE_HIT ) 
				status = CACHE_MISS;
			else begin
			 	status = CACHE_HIT;
				hit_count = hit_count + 1;
			end
					  			
			if ( status == CACHE_MISS )
				LRU_replacement;
			
			cmd = CPU_READ;
            		MESI;   
	    		
			if ( w_debug == DEBUG_MODE )
				$display("++++++++++++++++++++++++++++++++++++++++++++++++++++++++");   
            
		    	end

	SNOOP_INVALIDATE: 
			begin

			if ( w_debug == DEBUG_MODE )
		    		$display("\n------SNOOP INVALIDATE COMMAND------");
		    	
			status = CACHE_MISS;
		    
			for (way_itr = 0; way_itr < ASSOC; way_itr++) begin
				
				if ( Tag_Array[Index_Bits][way_itr] == Tag_Bits ) begin
					status    = CACHE_HIT;
					//hit_count = hit_count + 1;
					Way_Index = way_itr;
				end
		    	end
	
			MESI;
			
			if ( w_debug == DEBUG_MODE )
				$display("++++++++++++++++++++++++++++++++++++++++++++++++++++++++");	

		    	end
			
	SNOOP_READ: 
			begin

			if ( w_debug == DEBUG_MODE )
				$display("\n------snoop read COMMAND------");			
			
			status = CACHE_MISS;
			
			for (way_itr = 0; way_itr < ASSOC; way_itr++) begin

				if ( Tag_Array[Index_Bits][way_itr] == Tag_Bits ) begin
					status    = CACHE_HIT;
					//hit_count = hit_count + 1;
					Way_Index = way_itr;
				end
		    	end
		   					
			MESI;

			if ( w_debug == DEBUG_MODE )
	        		$display("++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
		    	
			end

	SNOOP_WRITE: 
			begin
			
			if ( w_debug == DEBUG_MODE )
				$display("\n-------snoop write COMMAND------");

			status = CACHE_MISS;
			
			for (way_itr = 0; way_itr < ASSOC; way_itr++) begin
				
				if ( Tag_Array[Index_Bits][way_itr] == Tag_Bits ) begin
					status    = CACHE_HIT;
					Way_Index = way_itr;

				end

				if ( status != CACHE_HIT ) 
					status  = CACHE_MISS;
				else
					MESI;
			end
			
			if ( w_debug == DEBUG_MODE )
				$display("++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
			
			end

	SNOOP_RWIM: 
			begin
			
			if ( w_debug == DEBUG_MODE )
				$display("\n------snoop rwim COMMAND------");
			
			status = CACHE_MISS;
			
			for (way_itr = 0; way_itr < ASSOC; way_itr++) begin
				
				if ( Tag_Array[Index_Bits][way_itr] == Tag_Bits ) begin
					status    = CACHE_HIT;
					Way_Index = way_itr;

				end

				if ( status != CACHE_HIT ) 
					status = CACHE_MISS;
				else
					MESI;				
			end
			
			if ( w_debug == DEBUG_MODE )
				$display("++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
			
			end

	CLEAR_CACHE: 
			begin
	
			if ( w_debug == DEBUG_MODE )
				$display("\n------Clear cache COMMAND------");
		  	
			status = CACHE_MISS;

		  	for (indx_itr = 0; indx_itr < INDEX; indx_itr++) begin     
        			LRU_Array[indx_itr] = '0;

				for (way_itr = 0; way_itr < ASSOC; way_itr++) begin
					Tag_Array[indx_itr][way_itr]   = 'z;
                			State_Array[indx_itr][way_itr] = I;
		
        			end
			end
			
			if ( w_debug == DEBUG_MODE )
				$display("++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
			
			end

	PRINT_CACHE: 
			begin
			Print;
			end

	//default:
		//	$display("\n------Invalid Command------");
			
	endcase
end


task LRU_access;

	for (way_itr = 0; way_itr < ASSOC; way_itr++) begin
	
		if ( Tag_Array[Index_Bits][way_itr] == Tag_Bits ) begin
			
			if ( w_debug == DEBUG_MODE )
				$display("Hit / Miss: Cache Hit");
			
			Way_Index = way_itr;		

			case(Way_Index) 
			0:
				begin  	
                		LRU_Array[Index_Bits][0] =  1'b0;
				LRU_Array[Index_Bits][1] =  1'b0;
                		LRU_Array[Index_Bits][3] =  1'b0;
                		end

        		1:
				begin
 				LRU_Array[Index_Bits][0] =  1'b0;
                		LRU_Array[Index_Bits][1] =  1'b0;
                		LRU_Array[Index_Bits][3] =  1'b1;
                		end

			2:
				begin  
				LRU_Array[Index_Bits][0] =  1'b0;
                		LRU_Array[Index_Bits][1] =  1'b1;
                		LRU_Array[Index_Bits][4] =  1'b0;
                		end

        		3:
				begin  
				LRU_Array[Index_Bits][0] =  1'b0;
                		LRU_Array[Index_Bits][1] =  1'b1;
				LRU_Array[Index_Bits][4] =  1'b1;
               		        end
				
			4:
				begin  
				LRU_Array[Index_Bits][0] =  1'b1;
                		LRU_Array[Index_Bits][2] =  1'b0;
				LRU_Array[Index_Bits][5] =  1'b0;
                		end

			5:
				begin  
				LRU_Array[Index_Bits][0] =  1'b1;
                		LRU_Array[Index_Bits][2] =  1'b0;
				LRU_Array[Index_Bits][5] =  1'b1;
                		end

			6:
				begin 
				LRU_Array[Index_Bits][0] =  1'b1;
                		LRU_Array[Index_Bits][2] =  1'b1;
				LRU_Array[Index_Bits][6] =  1'b0;
                		end

			8:
				begin  
				LRU_Array[Index_Bits][0] =  1'b1;
				LRU_Array[Index_Bits][2] =  1'b1;
				LRU_Array[Index_Bits][6] =  1'b1;
                		end
						
        		endcase
                    			 					
			status = CACHE_HIT;

			if ( w_debug == DEBUG_MODE )
				$display("Tag = %h LRU %b" ,address, LRU_Array[Index_Bits]);
        		break;
                
		end
	end
endtask


task LRU_replacement;

	if ( w_debug == DEBUG_MODE )
		$display("Hit / Miss: Cache Miss");

    	casez(LRU_Array[Index_Bits])
    	7'b0???0?0: 
			begin
			Way_Index 	         =  7;
       	       	        LRU_Array[Index_Bits][0] =  1'b1;
    	                LRU_Array[Index_Bits][2] =  1'b1;
    	                LRU_Array[Index_Bits][6] =  1'b1;
			end

	7'b1???0?0: 
			begin
			Way_Index 	         =  6;
			LRU_Array[Index_Bits][0] =  1'b1;
              	  	LRU_Array[Index_Bits][2] =  1'b1;
                	LRU_Array[Index_Bits][6] =  1'b0;
			end
         
    	7'b?0??1?0: 
			begin
			Way_Index 		 =  5;
               		LRU_Array[Index_Bits][0] =  1'b1;
                	LRU_Array[Index_Bits][2] =  1'b0;
                	LRU_Array[Index_Bits][5] =  1'b1;
			end
				
    	7'b?1??1?0: 
			begin
			Way_Index 		 =  4;
                	LRU_Array[Index_Bits][0] =  1'b1;
                	LRU_Array[Index_Bits][2] =  1'b0;
                	LRU_Array[Index_Bits][5] =  1'b0;
			end
	
	7'b??0??01: 
			begin
			Way_Index 		 =  3;
			LRU_Array[Index_Bits][0] =  1'b0;
            		LRU_Array[Index_Bits][1] =  1'b1;
			LRU_Array[Index_Bits][4] =  1'b1;
			end
	
    	7'b??1??01: 
			begin
			Way_Index		 =  2;
			LRU_Array[Index_Bits][0] =  1'b0;
            		LRU_Array[Index_Bits][1] =  1'b1;
			LRU_Array[Index_Bits][4] =  1'b0;
			end
        
    	7'b???0?11: 
			begin
			Way_Index 		 =  1;
			LRU_Array[Index_Bits][0] =  1'b0;
                	LRU_Array[Index_Bits][1] =  1'b0;
			LRU_Array[Index_Bits][3] =  1'b1;
			end

	7'b???1?11: 
			begin
			Way_Index 		 =  0;
			LRU_Array[Index_Bits][0] =  1'b0;
                	LRU_Array[Index_Bits][1] =  1'b0;
			LRU_Array[Index_Bits][3] =  1'b0;
			end

    	endcase
	
	evict_address = {Tag_Array[Index_Bits][Way_Index], Index_Bits, Byte_Select};

    	if ( w_debug == DEBUG_MODE )
		$display("Evict addess = 0x%x",evict_address);                		
endtask



/* Recheck L2 message functions later */
task MESI;
	if ( w_debug == DEBUG_MODE )
		$display("MESI:");

	//$display("Index_Bits:%h, Way_Index:%h, State_Array[Index_Bits][Way_Index]:%h", Index_Bits, Way_Index, State_Array[Index_Bits][Way_Index]);

	case(State_Array[Index_Bits][Way_Index])
	M:
		begin
		case(cmd)
			CPU_READ:   
					begin
					if ( status == CACHE_HIT ) begin
						State_Array[Index_Bits][Way_Index] = M;
						L2_message(SENDLINE, address);
	
						if ( w_debug == DEBUG_MODE )
							$display("State: M");

					end
					else begin											// CACHE_MISS
						L2_message(EVICTLINE, evict_address);
						BusOperation(WRITE, evict_address);
						BusOperation(READ, address);
							
						if (( Snoop_Result == HIT ) || ( Snoop_Result == HITM )) begin	
							State_Array[Index_Bits][Way_Index] = S;
							Tag_Array[Index_Bits][Way_Index]   = Tag_Bits;

							if ( w_debug == DEBUG_MODE )
								$display("State: S");

						end
						else if(Snoop_Result == NOHIT  ) begin
							State_Array[Index_Bits][Way_Index] = E;
							Tag_Array[Index_Bits][Way_Index]   = Tag_Bits;

							if ( w_debug == DEBUG_MODE )
								$display("State: E");

						end

						
						L2_message(SENDLINE, address);
					end
					end

			CPU_WRITE:  
					begin
					if ( status == CACHE_HIT ) begin
						State_Array[Index_Bits][Way_Index] = M;
						//L2_message(GETLINE, req_address);
						L2_message(SENDLINE, address);

						if ( w_debug == DEBUG_MODE )
							$display("State: M");
							
						end
						else begin											// CACHE_MISS
							L2_message(EVICTLINE, evict_address);
							BusOperation(WRITE, evict_address);
							BusOperation(RWIM, address);
							//
							
							State_Array[Index_Bits][Way_Index] = M;
							Tag_Array[Index_Bits][Way_Index]   = Tag_Bits;

							if ( w_debug == DEBUG_MODE )
								$display("State: M");
					
							L2_message(SENDLINE, address);

						end
					 end

			SNOOP_READ:
					begin
					if ( status == CACHE_HIT ) begin
						State_Array[Index_Bits][Way_Index] = S;
						PutSnoopResult(address, HITM);
						
						if ( w_debug == DEBUG_MODE )
							$display("State: S");	
						
						end	
                         end
	
			SNOOP_WRITE:
					begin
                        		end
	        
			

			SNOOP_INVALIDATE:
					begin 
					end
			
			
			SNOOP_RWIM: 	
					begin
					if ( status == CACHE_HIT ) begin
						State_Array[Index_Bits][Way_Index] = I;
						PutSnoopResult(address, HITM);	
						
						if ( w_debug == DEBUG_MODE )
							$display("State: I");

					end
					end
                        
			endcase
		end

	E:
		begin
			case(cmd)
			CPU_READ:   
					begin
					if ( status == CACHE_HIT ) begin
						State_Array[Index_Bits][Way_Index] = E;
						L2_message(SENDLINE, address);

						if ( w_debug == DEBUG_MODE )
							$display("State: E");
					
					end
					else begin											// CACHE_MISS
						L2_message(EVICTLINE, evict_address);
						BusOperation(WRITE, evict_address);
						BusOperation(READ, address);
							
						if (( Snoop_Result == HIT ) || ( Snoop_Result == HITM )) begin	
							State_Array[Index_Bits][Way_Index] = S;
							Tag_Array[Index_Bits][Way_Index]   = Tag_Bits;

							if ( w_debug == DEBUG_MODE )
								$display("State: S");

						end
						else if  (Snoop_Result == NOHIT ) begin
							State_Array[Index_Bits][Way_Index] = E;
							Tag_Array[Index_Bits][Way_Index]   = Tag_Bits;

							if ( w_debug == DEBUG_MODE )
								$display("State: E");

						end
						
						L2_message(SENDLINE, address);
					end
					end
			
			CPU_WRITE:  
					begin
					if ( status == CACHE_HIT ) begin
						State_Array[Index_Bits][Way_Index] = M;
						//L2_message(GETLINE, req_address);
						L2_message(SENDLINE, address);
						

						if ( w_debug == DEBUG_MODE )
							$display("State: M");
							
					end
					else begin											// CACHE_MISS
						L2_message(EVICTLINE, evict_address);
						BusOperation(WRITE, evict_address);
						BusOperation(RWIM, address);
						//L2_message(EVICTLINE, address);
							
						State_Array[Index_Bits][Way_Index] = M;
						Tag_Array[Index_Bits][Way_Index]   = Tag_Bits;

						if ( w_debug == DEBUG_MODE )
							$display("State: M");
						
						L2_message(SENDLINE, address);
					
					end	
					end

                        SNOOP_READ: 
					begin
					if ( status == CACHE_HIT ) begin
						State_Array[Index_Bits][Way_Index] = S;
						PutSnoopResult(address, HIT);

						if ( w_debug == DEBUG_MODE )
							$display("State: S");
					
					end
		        		end
						
			SNOOP_WRITE:
					begin
					end


			SNOOP_INVALIDATE: 
					begin
					end
			
			
			SNOOP_RWIM:
					begin 		
					if ( status == CACHE_HIT ) begin
						State_Array[Index_Bits][Way_Index] = I;
						PutSnoopResult(address, HIT);

						if ( w_debug == DEBUG_MODE )
							$display("State: I");

			                end
					end

			endcase
		end

	S:
		begin
		case(cmd)
			CPU_READ:   
					begin
					if ( status == CACHE_HIT ) begin
						State_Array[Index_Bits][Way_Index] = S;
						L2_message(SENDLINE, address);

						if ( w_debug == DEBUG_MODE )
							$display("State: S");

					end
					else begin											// CACHE_MISS
						L2_message(EVICTLINE, evict_address);
						BusOperation(WRITE, evict_address);
						BusOperation(READ, address);
							
						if (( Snoop_Result == HIT ) || ( Snoop_Result == HITM )) begin	
							State_Array[Index_Bits][Way_Index] = S;
							Tag_Array[Index_Bits][Way_Index]   = Tag_Bits;

							if ( w_debug == DEBUG_MODE )
								$display("State: S");

						end
						else if ( Snoop_Result == NOHIT ) begin
							State_Array[Index_Bits][Way_Index] = E;
							Tag_Array[Index_Bits][Way_Index]   = Tag_Bits;

							if ( w_debug == DEBUG_MODE )
								$display("State: E");	

						end

						L2_message(SENDLINE, address);
					end
					end
			
			CPU_WRITE:  
					begin
					if ( status == CACHE_HIT ) begin
						State_Array[Index_Bits][Way_Index] = M;
						L2_message(SENDLINE, address);
						BusOperation(INVALIDATE, address);

						if ( w_debug == DEBUG_MODE )
							$display("State: M");
							
					end
					else begin											// CACHE_MISS
						L2_message(EVICTLINE, evict_address);
						BusOperation(WRITE, evict_address);
						BusOperation(RWIM, address);
						//
							
						State_Array[Index_Bits][Way_Index] = M;
						Tag_Array[Index_Bits][Way_Index] = Tag_Bits;

						if ( w_debug == DEBUG_MODE )
							$display("State: M");

						L2_message(SENDLINE, address);

					end
					end
                        
                        SNOOP_READ:
					begin
					if ( status == CACHE_HIT ) begin
						State_Array[Index_Bits][Way_Index] = S;
						PutSnoopResult(address, HIT);

						if ( w_debug == DEBUG_MODE )
							$display("State: S");	

		        		end	
					end	


			SNOOP_WRITE: 
					begin

					end


			SNOOP_INVALIDATE:
					begin 	
					if ( status == CACHE_HIT ) begin
						State_Array[Index_Bits][Way_Index] = I;
						PutSnoopResult(address, HIT);

						if ( w_debug == DEBUG_MODE )
							$display("State: I");

					end
					end
			
			SNOOP_RWIM:
					begin
				 	if ( status == CACHE_HIT ) begin
						State_Array[Index_Bits][Way_Index] = I;
						PutSnoopResult(address, HIT);	

						if ( w_debug == DEBUG_MODE )	
							$display("State: I");
							
					end
					end

			endcase
		end

	I:
		begin
		case(cmd)
			CPU_READ:   
					begin
					if ( status == CACHE_HIT ) begin          
                                                
						BusOperation(READ, address);

						if (( Snoop_Result == HIT ) || ( Snoop_Result == HITM )) begin   
  
							State_Array[Index_Bits][Way_Index] = S;
							Tag_Array[Index_Bits][Way_Index]= Tag_Bits;

							if ( w_debug == DEBUG_MODE )
								$display("State: S");

						end
						else if ( Snoop_Result == NOHIT ) begin  
                        
							State_Array[Index_Bits][Way_Index] = E;
							Tag_Array[Index_Bits][Way_Index] = Tag_Bits;

							if ( w_debug == DEBUG_MODE )
								$display("State: E");

						end
            
						L2_message(SENDLINE, address);
                                        end
			  		else begin											// CACHE_MISS
						
						if (Tag_Array[Index_Bits][Way_Index] != 'z) begin
							L2_message(EVICTLINE, evict_address);                
							BusOperation(WRITE, evict_address);
						end

						BusOperation(READ, address);	
						if (( Snoop_Result == HIT ) || ( Snoop_Result == HITM )) begin	
								State_Array[Index_Bits][Way_Index] = S;
								Tag_Array[Index_Bits][Way_Index]   = Tag_Bits;

								if ( w_debug == DEBUG_MODE )
									$display("State: S");
                                                                
						end
						else if ( Snoop_Result == NOHIT ) begin
							State_Array[Index_Bits][Way_Index] = E;
							Tag_Array[Index_Bits][Way_Index]   = Tag_Bits;

							if ( w_debug == DEBUG_MODE )
								$display("State: E");

						end

						L2_message(SENDLINE, address);
					end
				end
			
			CPU_WRITE:  
					begin
					if ( status == CACHE_HIT ) begin
						
						BusOperation(RWIM, address);
						L2_message(SENDLINE, address);
						
						State_Array[Index_Bits][Way_Index] = M;

						if ( w_debug == DEBUG_MODE )
							$display("State: M");

					end
					else begin											// CACHE_MISS
						
						if (Tag_Array[Index_Bits][Way_Index] != 'z) begin
							L2_message(EVICTLINE, evict_address);                
							BusOperation(WRITE, evict_address);
						end

						BusOperation(RWIM, address);
						L2_message(SENDLINE, address);
							
						State_Array[Index_Bits][Way_Index] = M;
						Tag_Array[Index_Bits][Way_Index] = Tag_Bits;

						if ( w_debug == DEBUG_MODE )
							$display("State: M");

					end
					end

			SNOOP_READ:
					begin
					if ( status == CACHE_HIT ) begin
						State_Array[Index_Bits][Way_Index] = I;
						PutSnoopResult(address, NOHIT);

						if ( w_debug == DEBUG_MODE )
							$display("State: I");

					end
					end

			SNOOP_WRITE:
					begin
					end

			SNOOP_INVALIDATE:
					begin
					if ( status == CACHE_HIT ) begin
						State_Array[Index_Bits][Way_Index] = I;
						PutSnoopResult(address, NOHIT);

						if ( w_debug == DEBUG_MODE )
							$display("State = I");	

					end
			
			end

			SNOOP_RWIM:
					begin
				 	if ( status == CACHE_HIT ) begin
						State_Array[Index_Bits][Way_Index] = I;
						PutSnoopResult(address, NOHIT);	

						if ( w_debug == DEBUG_MODE )
							$display("State: I");

					end
					end
        		endcase
		end	
	endcase
endtask

task L2_message(input [2:0]L2_opt, input [31:0] Address);
	if ( w_mode == NORMAL_MODE ) begin
	if( GETLINE == L2_opt)  /* Request data for modified line in L1 */ 
		$display("L2 Message: Getline");
	if( SENDLINE          == L2_opt)  /* Send requested cache line to L1 */ 
		$display("L2 Message: SENDLINE");
	if( INVALIDATELINE    == L2_opt)  /* Invalidate a line in L1 */
		$display("L2 Message: INVALIDATELINE"); 

	if(  EVICTLINE        == L2_opt)
		$display("L2 Message: EVICTLINE");
	end
endtask: L2_message

task GetSnoopResult(input [31:0]Address, output snoop_result_t snoop_result);
	bit [1:0]snp_bits;
	assign snp_bits = Address[1:0];
        
	case(snp_bits)
			2'b00 	: snoop_result = HIT;
			2'b01 	: snoop_result = HITM;
			default : snoop_result = NOHIT;
	endcase

	//Snoop_Result = snoop_result;
endtask : GetSnoopResult


 
task BusOperation(input busopt_t busop, input [31:0]Address);
	bus_check = busop;
	GetSnoopResult(address, Snoop_Result);
	if ( w_mode == NORMAL_MODE )
		$display("Bus Operation : %s TOTAL_Address: %h, Get Snoop Result: %s\n",busop, Address, Snoop_Result);
endtask :  BusOperation



task PutSnoopResult(input [31:0]Address, input snoop_result_t putSnoop_result);
	if ( w_mode == NORMAL_MODE )
		$display("Put Snoop - Address: %h, Put Snoop Result: %s", Address, putSnoop_result);
	//putSnoop_Result = p_snoop_Result;
endtask : PutSnoopResult  

task Print;
	


	$display("\n\/\/\/\/\Valid lines in L3cache/\/\/\/\/");
	$display("| MESI State|  LRU|  Tag| Index|  Way|");

	for (indx_itr = 0; indx_itr < INDEX; indx_itr++) begin
		for (way_itr = 0; way_itr < ASSOC; way_itr++) begin
			
			if(State_Array[indx_itr][way_itr] != I) begin
			case(State_Array[indx_itr][way_itr])
			M : $display("|     M|%6b|%6d|%6d|%6d|",
						LRU_Array[indx_itr], Tag_Array[indx_itr][way_itr], indx_itr, way_itr);
			E : $display("|     E|%6b|%6d|%6d|%6d|",
						LRU_Array[indx_itr], Tag_Array[indx_itr][way_itr], indx_itr, way_itr);
			S : $display("|     S|%6b|%6d|%6d|%6d|",
						LRU_Array[indx_itr], Tag_Array[indx_itr][way_itr], indx_itr, way_itr);
			I : $display("|     I|%6b|%6d|%6d|%6d|",
						LRU_Array[indx_itr], Tag_Array[indx_itr][way_itr], indx_itr, way_itr);
			endcase  
			$display("|------|------|------|------|------|");
			end
		
		end
	end 

endtask : Print

endmodule 	
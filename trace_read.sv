
module trace_parse;

initial begin
parameter SILENT_MODE = 0, 
	  NORMAL_MODE = 1;

parameter L1_DATA_REQ_R  = 0,  // read request from L1 data cache 
	  L1_DATA_REQ_W  = 1,  // write request from L1 data cache 
	  L1_INST_REQ_R  = 2,  // read request from L1 instruction cache 
	  SNOOP_INVAL    = 3,  // snooped invalidate command 
	  SNOOP_REQ_R	 = 4,  // snooped read request 
	  SNOOP_REQ_W	 = 5,  // snooped write request 
	  SNOOP_MODREQ_R = 6,  // snooped read with intent to modify request  
	  RESET		 = 8,  // clear the cache and reset all state 
	  PRINT		 = 9;  // print contents and state of each valid cache line

int file, command;
string line, status;
logic [31:0] address;

int w_mode;
if($value$plusargs ("MODE=%d", w_mode))
begin
    if( w_mode == NORMAL_MODE)
	$display ("Mode: NORMAL_MODE");
    else
	$display ("Mode: SILENT_MODE");

end

file = $fopen("./trace.txt","r");

if(file)
 $display("File: trace.txt\tStatus: Open\nPrinting Contents");

else
 $display("File: trace.txt\tStatus: Fail");

while(!$feof(file))
	begin
	$fgets(line,file);
	$sscanf(line,"%d %h",command,address);
	$display("%d %h",command,address);

	case(command)
	  L1_DATA_REQ_R  :$display("Command: L1_DATA_REQ_R"); 
	  L1_DATA_REQ_W  :$display("Command: L1_DATA_REQ_W ");
	  L1_INST_REQ_R  :$display("Command: L1_INST_REQ_R "); 
	  SNOOP_INVAL    :$display("Command: SNOOP_INVAL   ");
	  SNOOP_REQ_R    :$display("Command: SNOOP_REQ_R   ");
	  SNOOP_REQ_W	 :$display("Command: SNOOP_REQ_W   ");
	  SNOOP_MODREQ_R :$display("Command: SNOOP_MODREQ_R");
	  RESET		 :$display("Command: RESET");
	  PRINT		 :$display("Command: PRINT");
	endcase

end
end


endmodule
	
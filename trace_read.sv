import cache_define ::*;


module trace_parse();

parameter    SILENT_MODE = 0, 
	     NORMAL_MODE = 1;

int          file;
string       line, status;
logic [31:0] address;
logic [4:0]  command;

int          w_mode;

cache DUT(.address(address),.command(command));

initial begin



if($value$plusargs ("MODE=%d", w_mode))
begin
    if( w_mode == NORMAL_MODE)
	$display ("Mode: NORMAL_MODE");
    else
	$display ("Mode: SILENT_MODE");

end

file = $fopen("./ECE585_Final_Project/trace.txt","r");

if(file) begin
 $display("File Opened");
 while(!$feof(file))
	begin
	$fgets(line,file);
	#20
	$sscanf(line,"%d %h",command,address);
        #20
	$display("Command = %d Address = %h",command,address);
      
/*
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
*/


end

end
else
 $display("File: trace.txt\tStatus: Fail");




end


endmodule
	
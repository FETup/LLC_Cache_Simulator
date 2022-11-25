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
			#50;
			$sscanf(line,"%d %h",command,address);
        		#50;
	//$display("Command = %d Address = %h",command,address);
       	


		end

	end
	else
 		$display("File: trace.txt\tStatus: Fail");




end


endmodule
	
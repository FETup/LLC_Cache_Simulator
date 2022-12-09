import cache_define ::*;


module trace_parse();

int           file;
string 	      filename;
string        line, status;
logic  [31:0] address;
logic  [3 :0] command;
logic 	      error_status; 
int        w_mode;
int 	   w_debug;
int 	   w_eof;

cache DUT(
	.address(address),
	.command(command),
	.w_mode(w_mode),
	.w_debug(w_debug),
	.w_eof(w_eof)
	);

initial begin

	if($value$plusargs ("MODE=%d", w_mode));

	if ( $value$plusargs ("DEBUG=%d", w_debug))
	begin
    		if ( w_debug == DEBUG_MODE )
			$display ("Mode: DEBUG_MODE");

	end
	
	if ( $value$plusargs ("FILE=%s", filename))
		file = $fopen(filename,"r");
	else
		$display("File not specified. Please add FILE = <filename> in compilation");

	if ( file ) begin
		if ( w_debug == DEBUG_MODE )
 			$display("File Opened");
		
		
 		while ( !$feof(file) ) begin
			w_eof = FALSE;
			error_status =$fgets(line,file);
			#50;
			error_status = $sscanf(line,"%d %h",command,address);
	
			error_status = 0;
			if (( command == 7 ) || ( command >= 10 )) begin
				$display("Invalid command");
				error_status = 1;
			end
			
			if ( error_status )
				$stop;
			#50;
		end
		w_eof = TRUE;
		$fclose(file);

	end
	else
 		$display("File: trace.txt\tStatus: Fail");
end

endmodule
	
module trace_parse;

initial begin
int file;

file = $fopen("./trace.txt","r");

if(file)
 $display("File Opened");

else
 $display("Fail");

end

endmodule
	
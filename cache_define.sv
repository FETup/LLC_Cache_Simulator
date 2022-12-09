package cache_define;

parameter SILENT_MODE = 0, 
	  NORMAL_MODE = 1;

parameter TRUE        = 1;
parameter FALSE       = 0; 

parameter DEBUG_MODE  = 1;

parameter ADDR_SIZE   = 32;
parameter CACHE_SIZE  = 16000000;
parameter ASSOC       = 8;
parameter CACHE_LINE  = 64;
parameter STATE_WIDTH = 2;


parameter INDEX       = (CACHE_SIZE/(ASSOC * CACHE_LINE));      
parameter INDEX_BITS  = $clog2(INDEX);
parameter BYTE_BITS   = $clog2(CACHE_LINE);
parameter TAG_BITS    = ADDR_SIZE - (INDEX_BITS + BYTE_BITS);
parameter LRU_BITS    = ASSOC- 1;
parameter ASSOC_BITS  = $clog2(ASSOC);

parameter CACHE_HIT         = 1;
parameter CACHE_MISS        = 0;


parameter CPU_READ          = 0;
parameter CPU_WRITE         = 1;

parameter DATA_READ         = 0;
parameter DATA_WRITE        = 1;
parameter INST_READ         = 2;
parameter SNOOP_INVALIDATE  = 3;
parameter SNOOP_READ        = 4;
parameter SNOOP_WRITE       = 5;
parameter SNOOP_RWIM        = 6;
parameter CLEAR_CACHE	    = 8;
parameter PRINT_CACHE	    = 9;

parameter GETLINE           = 1;  /* Request data for modified line in L1 */ 
parameter SENDLINE          = 2;  /* Send requested cache line to L1 */ 
parameter INVALIDATELINE    = 3;  /* Invalidate a line in L1 */ 
parameter EVICTLINE         = 4;  /* Evict a line from L1 */
/*
parameter HIT               = 2'b00;
parameter HITM              = 2'b01;
parameter NOHIT             = 2'b10;
*/

parameter M                 = 0;
parameter E                 = 1;
parameter S                 = 2;
parameter I                 = 3; 



/* Snoop Result and Bus State Declarations */
typedef enum logic [2:0] {NOHIT, HIT, HITM} snoop_result_t;

typedef enum logic [2:0] {READ, WRITE, INVALIDATE, RWIM} busopt_t;


endpackage

package cache_define;

parameter ADDR_SIZE  = 32;
parameter CACHE_SIZE = 1024;
parameter ASSOC      = 4;
parameter CACHE_LINE  = 64;


parameter INDEX       = (CACHE_SIZE/(ASSOC * CACHE_LINE));      
parameter INDEX_BITS  = $clog2(CACHE_SIZE/(ASSOC * CACHE_LINE));
parameter BYTE_BITS   = $clog2(CACHE_LINE);
parameter TAG_BITS    = ADDR_SIZE - (INDEX_BITS + BYTE_BITS);
parameter LRU_BITS    = ASSOC- 1;

parameter HIT         = 1;
parameter MISS        = 2;

endpackage
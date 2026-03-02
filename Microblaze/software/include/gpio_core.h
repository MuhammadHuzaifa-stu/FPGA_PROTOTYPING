class GpoCore {
    // register map
    enum {
        DATA_REG = 0 // data register
    };
public:
    GpoCore(uint32_t core_base_addr);       // constructor
    ~GpoCore();                             // destructor; not used
    // methods
    void write(uint32_t data);              // write a 32-bit word
    void write(int bit_value, int bit_pos); // write 1-bit
private:
    uint32_t base_addr;
    uint32_t wr_data;                       //same as GPO core data reg 
};

class GpiCore {
    // register map
    enum {
        DATA_REG = 0 // data register
    };
public:
    GpiCore(uint32_t core_base_addr);       // constructor
    ~GpiCore();                             // destructor; not used 
    // methods
    uint32_t read();                        // read a 32-bit word
    int read(int bit_pos);                  // read 1-bit
private:
    uint32_t base_addr;
};
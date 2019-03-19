#include <unordered_map>

#include "params/RubyCache.hh"
#include "sim/sim_object.hh"

class RCTBuffer : public SimObject
{
  public:
    typedef RubyCacheParams Params;
    typedef std::unordered_map<Addr,std::set<Cycles>>::iterator RCT_It;
    RCTBuffer(const Params *p);
    //public methods
    void insert(Addr address, Cycles ret_cycle);
    bool isFull(Addr address);
    void removeOldEntries(Cycles cur_cycle);
  private:
    const uint16_t max_map_size;
    const uint16_t max_set_size;
    std::unordered_map<Addr, std::set<Cycles>> rct_buffer;
    /* simple statistics so we can bound size of implementation */
    uint16_t max_num_ctrs_used;
    uint16_t max_num_entries_used;
};


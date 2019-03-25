#include <random>
#include <unordered_map>

#include "params/RubyCache.hh"
#include "sim/sim_object.hh"

class RCTBuffer : public SimObject
{
  public:
    typedef RubyCacheParams Params;
    typedef std::map <Cycles, uint32_t>::iterator hist_it;
    typedef std::unordered_map<Addr, Cycles>::iterator tracker_it;
    typedef std::unordered_map<Addr,std::set<Cycles>>::iterator RCT_it;
    RCTBuffer(const Params *p);
    //public methods
    void insert(Addr address, Cycles ret_cycle);
    bool isFull(Addr address);
    void removeOldEntries(Cycles cur_cycle);
    void recordRequest(Addr address, Cycles cur_cycle);
    void updateHistogram(Addr address, Cycles cur_cycle);
    Cycles sampleHistogram();
  private:
    const uint16_t max_map_size;
    const uint16_t max_set_size;
    std::unordered_map<Addr, std::set<Cycles>> rct_buffer;
    /* simple statistics so we can bound size of implementation */
    uint16_t max_num_ctrs_used;
    uint16_t max_num_entries_used;
    /* histogram of miss lengths*/
    std::map <Cycles, uint32_t> histogram;
    // need to track incoming requests because
    // ruby doesn't keep track of length of request
    // only sequencer knows
    std::unordered_map<Addr, Cycles> tracker;
    /* internal helpers */
    void calcIntervals(uint32_t &max,
            std::map<Cycles,
            std::pair<uint32_t,uint32_t>> &intervals);
    Cycles findEntry(uint32_t loc,
            const std::map<Cycles,
            std::pair<uint32_t,uint32_t>> &intervals);
};


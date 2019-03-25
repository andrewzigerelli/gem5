#ifndef __MEM_RUBY_STRUCTURES_RCTBUFFER_HH__
#define __MEM_RUBY_STRUCTURES_RCTBUFFER_HH__

#include "mem/ruby/structures/RCTBuffer.hh"

#include "base/trace.hh"
#include "debug/RCT.hh"
#include "debug/RCTStats.hh"

RCTBuffer::RCTBuffer(const Params *p) :
    SimObject(p),
    max_map_size(p->rct_size),
    max_set_size(p->num_ctrs) {
        max_num_ctrs_used = 0;
        max_num_entries_used = 0;
    }
void
RCTBuffer::insert(Addr address, Cycles ret_cycle) {
    DPRINTFR(RCT, "inserted 0x%llx to return at %llu\n",
            address, ret_cycle);

    RCT_it loc;
    int ctrs;
    loc = rct_buffer.find(address);
    if (loc == rct_buffer.end()) { /*new entry*/
        rct_buffer[address] = std::set<Cycles> { ret_cycle };
        loc = rct_buffer.find(address);
    }
    else {
        loc->second.insert(ret_cycle);
        if (DTRACE(RCT)) {
            for (Cycles const& cycle: loc->second) {
                DPRINTFR(RCT, "cycle %llu\n", cycle);
            }
        }
        DPRINTFR(RCT, "number of counters is %d\n", ctrs);
    }
    DPRINTFR(RCT, "RCT buffer size is %d\n", rct_buffer.size());
    if ( rct_buffer.size() > max_num_entries_used ) {
        max_num_entries_used = rct_buffer.size();
        DPRINTFR(RCTStats, "Max buffer size: %u\n", max_num_entries_used);
    }
    /* see if we need to update max stats */
    ctrs = loc->second.size();
    if (ctrs > max_num_ctrs_used) {
        max_num_ctrs_used = ctrs;
        DPRINTFR(RCTStats, "Max counters %u\n", max_num_ctrs_used);
    }
}
bool
RCTBuffer::isFull(Addr address) {
    std::unordered_map<Addr, std::set<Cycles>>::iterator loc;
    loc = rct_buffer.find(address);
    if (loc == rct_buffer.end()) { /* not here */
        if (rct_buffer.size() == max_map_size) {
            DPRINTFR(RCT, "map full\n");
            /* we are full */
            return true;
        }
        else { /* we can allocate new entry */
            return false;
        }
    }
    else { /* check if all entries are used */
        int size = loc->second.size();
        if (size == max_set_size) {
            return true;
        }
        else {
            return false;
        }
    }
}
void
RCTBuffer::removeOldEntries(Cycles cur_cycle) {
    RCT_it it = rct_buffer.begin();
    while (it != rct_buffer.end()) {
        for (Cycles const& cycle: it->second) { /*remove old counters */
            if (cycle <= cur_cycle) {
                DPRINTFR(RCT, "current cycle %llu\n", cur_cycle);
                DPRINTFR(RCT, "free %llu\n, addr %llx\n", cycle, it->first);
                it->second.erase(cycle);
            }
            /* since set is ordered, we can break the inner for loop early if
             * false. But we don't do that here in case we switch to
             * unordered_set later */
        }
        /* see if we can free buffer entry */
        if (it->second.size() == 0)  {
            DPRINTFR(RCT, "we can free address %llx\n", it->first);
            it = rct_buffer.erase(it);
        }
        else {
            it++;
        }
    }
}
void
RCTBuffer::recordRequest(Addr address, Cycles cur_cycle) {
    tracker_it loc;
    loc = tracker.find(address);
    /* may need different logic */
    /* if another request for same address comes */
    if (loc != tracker.end()) {
        DPRINTFR(RCT || RCTStats, "Request was already recorded!\n");
        assert(loc == tracker.end());
    }
    tracker[address] = cur_cycle;
}
void
RCTBuffer::updateHistogram(Addr address, Cycles cur_cycle) {
    tracker_it loc = tracker.find(address);
    assert(loc != tracker.end()); /* if not there, something is wrong*/
    Cycles latency = cur_cycle - loc->second;
    if (latency < 1000) { /* larger is rare, ignore it */
        ++histogram[latency];
    }
    /* clear req from record */
    tracker.erase(loc);
}
Cycles
RCTBuffer::sampleHistogram() {
    /* create disjoint intervals, sized accoring to freq */
    std::map<Cycles, std::pair<uint32_t,uint32_t>> intervals;
    uint32_t max;
    /* actually calculate ranges and max for uniform_dist*/
    calcIntervals(max, intervals);

    /* sample from histogram by sampling uniform dist, then finding correct
     * interval */
    std::uniform_int_distribution<uint32_t> uniform_dist(1, max);
    std::random_device rd;
    std::mt19937 gen(rd()); /* entropy may be low, so use prng seeded with rd*/
    uint32_t loc = uniform_dist(gen);
    Cycles entry = findEntry(loc, intervals);
    return entry;

}
void
RCTBuffer::calcIntervals(uint32_t &max,
        std::map<Cycles, std::pair<uint32_t,uint32_t>> &intervals) {
    /* create disjoint intervals, sized accoring to freq */
    uint32_t length, upper_bound;
    uint32_t lower_bound = 1;
    hist_it it;
    for (it = histogram.begin(); it!= histogram.end(); it++) {
        length = it->second;
        max += length;
        upper_bound = lower_bound + length - 1;
        intervals[it->first] = std::make_pair(lower_bound, upper_bound);
        /* for next iteration */
        lower_bound = upper_bound + 1;
    }
}
Cycles
RCTBuffer::findEntry(uint32_t loc,
        const std::map<Cycles, std::pair<uint32_t,uint32_t>> &intervals){
    /* given loc, finds entry in intervals s.t.
     * pair(1) <= loc <= pair(2) */
    std::map<Cycles, std::pair<uint32_t,uint32_t>>::const_iterator \
        it = intervals.begin();
    std::pair<uint32_t, uint32_t> interval;
    while (it != intervals.end()) {
        interval = it->second;
        if ( loc >= interval.first && loc <= interval.second ) {
            return it->first;
        }
        it++;
    }
    assert(it != intervals.end()); //should never get here
    exit(1); //stop compiler from complaining
}
#endif // __MEM_RUBY_STRUCTURES_RCTBUFFER_HH__

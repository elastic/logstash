package org.logstash.ackedqueue;

import com.logstash.Event;

public class Queue {

    // @param event the Event to write to the queue
    // @return long written sequence number
    public long write(Event event) {
        // TBD
        return 0;
    }

    // @param seqNum the event sequence number upper bound for which persistence should be garanteed (by fsync'int)
    public void ensurePersistedUpto(long seqNum) {
        // TBD
    }

    public Batch readBatch(int limit) {
        // TBD

        return null;
    }

    public void ack(long[] seqNums) {
        // TBD
    }


    public Queue recover() {
        // TBD

        // recovery or rehydrate queue from disk
        // read checkpoint.head and:
        // iterate through all beheaded pages and recover each page state
        // handle last page situation
        // create new head page, regardless of state of previous head page

        return null;
    }

}

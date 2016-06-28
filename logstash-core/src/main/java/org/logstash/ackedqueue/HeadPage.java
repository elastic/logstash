package org.logstash.ackedqueue;

import com.logstash.Event;

public class HeadPage extends Page {

    // TBD the HeadPage will checkpoints to checkpoint.head

    public HeadPage() {
        // TBD
        // create new page file
        // write a version number as first byte(s)
        // write header? (some debugging info, logstash version?, queue version, etc)
    }

    public boolean hasSpace(int byteSize) {
        // TBD
        return true;
    }

    public void write(byte[] bytes, Event event) {
        // TBD
    }

    BeheadedPage behead() {
        // TBD
        // closes this page
        // creates a new BeheadedPage, passing its own structure
        // calls BeheadedPage.checkpoint
        // return this new BeheadedPage

        return null;
    }
}

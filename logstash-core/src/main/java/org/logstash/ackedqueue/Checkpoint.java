package org.logstash.ackedqueue;

public class Checkpoint {

//    Checkpoint file structure
//
//    byte version;
//    int pageNum;
//    int firstUnackedPageNum;
//    long minSeqNum;
//    int elementCount;


    // TODO: change to provate fields + getter/setters below
    public int pageNum;
    public int firstUnackedPageNum; // only valid in the head checkpoint
    public long minSeqNum;     // per page
    public int elementCount;     // per page

    public byte VERSION = 0;

    public Checkpoint() {
        // TODO:
    }

    public void write(String filename) {
        // TODO:

        // open file for write
        // truncate to start
        // serialize attributes
        // prepend header/version?
        // write bytes
        // flush/fsync/close
    }

    static Checkpoint read(String filename) {
        // TODO:

        // open file for read
        // read fist version/header bytes
        // per verion schema read rest of bytes
        // deserialize into new Checkpoint
        // return checkpoint

        return null;
    }
}

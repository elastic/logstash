package org.logstash.ackedqueue;

import org.logstash.common.io.ByteArrayStreamOutput;
import org.logstash.common.io.ByteBufferStreamInput;
import org.logstash.common.io.InputStreamStreamInput;
import org.logstash.common.io.StreamInput;
import org.logstash.common.io.StreamOutput;

import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

public class Checkpoint {

//    Checkpoint file structure
//
//    byte version;
//    int pageNum;
//    int firstUnackedPageNum;
//    long minSeqNum;
//    int elementCount;

    static final int BUFFER_SIZE = 1 // version
            + Integer.BYTES  // pageNum
            + Integer.BYTES  // firstUnackedPageNum
            + Long.BYTES     // minSeqNum
            + Integer.BYTES; // eventCount

    private int pageNum;
    private int firstUnackedPageNum; // only valid in the head checkpoint
    private long minSeqNum;     // per page
    private int elementCount;     // per page

    public static final byte VERSION = 0;

    public Checkpoint(int pageNum, int firstUnackedPageNum, long minSeqNum, int eventCount) {
        this.pageNum = pageNum;
        this.firstUnackedPageNum = firstUnackedPageNum;
        this.minSeqNum = minSeqNum;
        this.elementCount = eventCount;
    }

    public Checkpoint(StreamInput in) throws IOException {
        pageNum = in.readInt();
        firstUnackedPageNum = in.readInt();
        minSeqNum = in.readLong();
        elementCount = in.readInt();
    }

    public void write(String filename) {
        try {
            FileOutputStream fos = new FileOutputStream(filename, false);
            write(fos.getChannel());
            fos.flush();
            fos.getFD().sync();
            fos.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public void write(FileChannel channel) throws IOException {
        byte[] buffer = new byte[BUFFER_SIZE];
        final ByteArrayStreamOutput out = new ByteArrayStreamOutput(buffer);
        write(out);
        ByteBuffer buf = ByteBuffer.wrap(buffer);
        while(buf.hasRemaining()) {
            channel.write(buf);
        }
    }

    public void write(StreamOutput out) throws IOException {
        out.writeByte(VERSION);
        out.writeInt(pageNum);
        out.writeInt(firstUnackedPageNum);
        out.writeLong(minSeqNum);
        out.writeInt(elementCount);
    }

    static Checkpoint read(byte[] bytes) throws IOException {
        // this should only be used to help with unit tests
        return read(new ByteBufferStreamInput(ByteBuffer.wrap(bytes)));
    }

    static Checkpoint read(StreamInput si) throws IOException {
        byte version = si.readByte();
        // TODO - build reader for this version
        if (version == VERSION) {
            return new Checkpoint(si);
        }
        throw new IOException("Unknown file format version: " + version);
    }

    static Checkpoint read(Path path) throws IOException {
        InputStream in = Files.newInputStream(path);
        return read(new InputStreamStreamInput(in));
    }

    static Checkpoint read(String filename) throws IOException{
        Path path  = Paths.get(filename);
        return read(path);
    }

    public int getPageNum() {
        return pageNum;
    }

    public int getFirstUnackedPageNum() {
        return firstUnackedPageNum;
    }

    public long getMinSeqNum() {
        return minSeqNum;
    }

    public int getElementCount() {
        return elementCount;
    }

}

package org.logstash.common.io;

import org.logstash.ackedqueue.Checkpoint;

import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

public class FileCheckpointIO  implements CheckpointIO {
//    Checkpoint file structure see Checkpoint

    private int pageNum;       // local per-page page number
    private long minSeqNum;    // local per-page minimum seqNum
    private int elementCount;        // local per-page element count
    private long firstUnackedSeqNum; // local per-page unacknowledged tracking
    private int firstUnackedPageNum; // queue-wide global pointer, only valid in the head checkpoint

    private final String filePath;

    public static final byte VERSION = 0;

    public FileCheckpointIO(String source) throws IOException{
        this.filePath = source;
    }

    @Override
    public void read() throws IOException {
        Path path  = Paths.get(this.filePath);
        StreamInput si = new InputStreamStreamInput(Files.newInputStream(path));
        byte version = si.readByte();
        // TODO - build reader for this version
        if (version != VERSION) {
            throw new IOException("Unknown file format version: " + version);
        }
        this.pageNum = si.readInt();
        this.firstUnackedPageNum = si.readInt();
        this.firstUnackedSeqNum = si.readLong();
        this.minSeqNum = si.readLong();
        this.elementCount = si.readInt();
    }

    @Override
    public void write(int firstUnackedPageNum, long firstUnackedSeqNum, int elementCount)  throws IOException{
        this.firstUnackedPageNum = firstUnackedPageNum;
        this.firstUnackedSeqNum = firstUnackedSeqNum;
        this.elementCount = elementCount;

        try {
            FileOutputStream fos = new FileOutputStream(filePath, false);
            write(fos.getChannel());
            fos.flush();
            fos.getFD().sync();
            fos.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private void write(FileChannel channel) throws IOException {
        byte[] buffer = new byte[Checkpoint.BUFFER_SIZE];
        final ByteArrayStreamOutput out = new ByteArrayStreamOutput(buffer);
        write(out);
        ByteBuffer buf = ByteBuffer.wrap(buffer);
        while(buf.hasRemaining()) {
            channel.write(buf);
        }
    }

    private void write(StreamOutput out) throws IOException {
        out.writeByte(VERSION);
        out.writeInt(this.pageNum);
        out.writeInt(this.firstUnackedPageNum);
        out.writeLong(this.firstUnackedSeqNum);
        out.writeLong(this.minSeqNum);
        out.writeInt(this.elementCount);
    }

    public int getPageNum() {
        return this.pageNum;
    }

    public long getMinSeqNum() {
        return this.minSeqNum;
    }

    public long getFirstUnackedSeqNum() {
        return this.firstUnackedSeqNum;
    }

    public int getElementCount() {
        return this.elementCount;
    }

    public int getFirstUnackedPageNum() {
        return this.firstUnackedPageNum;
    }

}

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
//    Checkpoint file structure as handled by CheckpointIO
//
//    byte version;
//    int pageNum;
//    int firstUnackedPageNum;
//    long firstUnackedSeqNum;
//    long minSeqNum;
//    int elementCount;

    public static final int BUFFER_SIZE = 1 // version
            + Integer.BYTES  // pageNum
            + Integer.BYTES  // firstUnackedPageNum
            + Long.BYTES     // firstUnackedSeqNum
            + Long.BYTES     // minSeqNum
            + Integer.BYTES  // eventCount
            + Long.BYTES;    // checksum

    private final String dirPath;

    public FileCheckpointIO(String dirPath) {
        this.dirPath = dirPath;
    }

    @Override
    public Checkpoint read(String fileName) throws IOException {
        Path path  = Paths.get(fileName); // TODO: integrate dirPath
        StreamInput issi = new InputStreamStreamInput(Files.newInputStream(path));
        BufferedChecksumStreamInput crcsi = new BufferedChecksumStreamInput(issi);
        byte version = crcsi.readByte();
        // TODO - build reader for this version
        int pageNum = crcsi.readInt();
        int firstUnackedPageNum = crcsi.readInt();
        long firstUnackedSeqNum = crcsi.readLong();
        long minSeqNum = crcsi.readLong();
        int elementCount = crcsi.readInt();
        long readCrc32 = crcsi.readLong();
        long calcCrc32 = crcsi.getChecksum();
        if (readCrc32 != calcCrc32) {
            throw new IOException(String.format("Checkpoint checksum mismatch, expected: %d, actual: %d", calcCrc32, readCrc32));
        }
        if (version != Checkpoint.VERSION) {
            throw new IOException("Unknown file format version: " + version);
        }

        return new Checkpoint(pageNum, firstUnackedPageNum, firstUnackedSeqNum, minSeqNum, elementCount);
    }

    @Override
    public void write(String fileName, int pageNum, int firstUnackedPageNum, long firstUnackedSeqNum, long minSeqNum, int elementCount) throws IOException {
        Checkpoint checkpoint = new Checkpoint(pageNum, firstUnackedPageNum, firstUnackedSeqNum, minSeqNum, elementCount);
        FileOutputStream fos = new FileOutputStream(fileName, false);
        write(checkpoint, fos.getChannel());
        fos.flush();
        fos.getFD().sync();
        fos.close();
    }

    @Override
    public void purge(String fileName) throws IOException {
        Path path = Paths.get(fileName);
        Files.delete(path);
    }

    private void write(Checkpoint checkpoint, FileChannel channel) throws IOException {
        byte[] buffer = new byte[BUFFER_SIZE];
        final ByteArrayStreamOutput baso = new ByteArrayStreamOutput(buffer);
        write(checkpoint, baso);
        ByteBuffer buf = ByteBuffer.wrap(buffer);
        while(buf.hasRemaining()) {
            channel.write(buf);
        }
    }

    private void write(Checkpoint checkpoint, StreamOutput so) throws IOException {
        final BufferedChecksumStreamOutput out = new BufferedChecksumStreamOutput(so);
        out.writeByte(Checkpoint.VERSION);
        out.writeInt(checkpoint.getPageNum());
        out.writeInt(checkpoint.getFirstUnackedPageNum());
        out.writeLong(checkpoint.getFirstUnackedSeqNum());
        out.writeLong(checkpoint.getMinSeqNum());
        out.writeInt(checkpoint.getElementCount());
        out.writeLong(out.getChecksum());
    }
}

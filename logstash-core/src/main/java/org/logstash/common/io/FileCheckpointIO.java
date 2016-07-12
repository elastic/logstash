package org.logstash.common.io;

import org.logstash.ackedqueue.Checkpoint;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

public class FileCheckpointIO  implements CheckpointIO {
//    Checkpoint file structure
//
//    byte version;
//    int pageNum;
//    int firstUnackedPageNum;
//    long firstUnackedSeqNum;
//    long minSeqNum;
//    int elementCount;

    public static final int BUFFER_SIZE = Short.BYTES // version
            + Integer.BYTES  // pageNum
            + Integer.BYTES  // firstUnackedPageNum
            + Long.BYTES     // firstUnackedSeqNum
            + Long.BYTES     // minSeqNum
            + Integer.BYTES  // eventCount
            + Integer.BYTES;    // checksum

    private final String dirPath;

    public FileCheckpointIO(String dirPath) {
        this.dirPath = dirPath;
    }

    @Override
    public Checkpoint read(String fileName) throws IOException {
        Path path = Paths.get(dirPath, fileName);
        InputStream is = Files.newInputStream(path);
        return read(new BufferedChecksumStreamInput(new InputStreamStreamInput(is)));
    }

    @Override
    public Checkpoint write(String fileName, int pageNum, int firstUnackedPageNum, long firstUnackedSeqNum, long minSeqNum, int elementCount) throws IOException {
        Path path = Paths.get(dirPath, fileName);
        Checkpoint checkpoint = new Checkpoint(pageNum, firstUnackedPageNum, firstUnackedSeqNum, minSeqNum, elementCount);
        final byte[] buffer = new byte[BUFFER_SIZE];
        write(checkpoint, buffer);
        Files.write(path, buffer);
        return checkpoint;
    }

    @Override
    public void purge(String fileName) throws IOException {
        Path path = Paths.get(fileName);
        Files.delete(path);
    }

    private Checkpoint read(BufferedChecksumStreamInput crcsi) throws IOException {
        int version = (int) crcsi.readShort();
        // TODO - build reader for this version
        int pageNum = crcsi.readInt();
        int firstUnackedPageNum = crcsi.readInt();
        long firstUnackedSeqNum = crcsi.readLong();
        long minSeqNum = crcsi.readLong();
        int elementCount = crcsi.readInt();

        int calcCrc32 = (int)crcsi.getChecksum();
        int readCrc32 = crcsi.readInt();
        if (readCrc32 != calcCrc32) {
            throw new IOException(String.format("Checkpoint checksum mismatch, expected: %d, actual: %d", calcCrc32, readCrc32));
        }
        if (version != Checkpoint.VERSION) {
            throw new IOException("Unknown file format version: " + version);
        }

        return new Checkpoint(pageNum, firstUnackedPageNum, firstUnackedSeqNum, minSeqNum, elementCount);
    }

    private void write(Checkpoint checkpoint, byte[] buf) throws IOException {
        BufferedChecksumStreamOutput output = new BufferedChecksumStreamOutput(new ByteArrayStreamOutput(buf));
        output.writeShort((short)Checkpoint.VERSION);
        output.writeInt(checkpoint.getPageNum());
        output.writeInt(checkpoint.getFirstUnackedPageNum());
        output.writeLong(checkpoint.getFirstUnackedSeqNum());
        output.writeLong(checkpoint.getMinSeqNum());
        output.writeInt(checkpoint.getElementCount());
        output.writeInt((int)output.getChecksum());
    }
}

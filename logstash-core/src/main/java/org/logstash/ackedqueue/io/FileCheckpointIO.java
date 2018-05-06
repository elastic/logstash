package org.logstash.ackedqueue.io;

import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.zip.CRC32;
import org.logstash.ackedqueue.Checkpoint;

public class FileCheckpointIO implements CheckpointIO {
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

    /**
     * Using {@link java.nio.DirectByteBuffer} to avoid allocations and copying in
     * {@link FileChannel#write(ByteBuffer)} and {@link CRC32#update(ByteBuffer)} calls.
     */
    private final ByteBuffer buffer = ByteBuffer.allocateDirect(BUFFER_SIZE);

    private final CRC32 crc32 = new CRC32();

    private static final String HEAD_CHECKPOINT = "checkpoint.head";
    private static final String TAIL_CHECKPOINT = "checkpoint.";
    private final Path dirPath;

    public FileCheckpointIO(Path dirPath) {
        this.dirPath = dirPath;
    }

    @Override
    public Checkpoint read(String fileName) throws IOException {
        return read(
            ByteBuffer.wrap(Files.readAllBytes(dirPath.resolve(fileName)))
        );
    }

    @Override
    public Checkpoint write(String fileName, int pageNum, int firstUnackedPageNum, long firstUnackedSeqNum, long minSeqNum, int elementCount) throws IOException {
        Checkpoint checkpoint = new Checkpoint(pageNum, firstUnackedPageNum, firstUnackedSeqNum, minSeqNum, elementCount);
        write(fileName, checkpoint);
        return checkpoint;
    }

    @Override
    public void write(String fileName, Checkpoint checkpoint) throws IOException {
        write(checkpoint, buffer);
        buffer.flip();
        final Path tmpPath = dirPath.resolve(fileName + ".tmp");
        try (FileOutputStream out = new FileOutputStream(tmpPath.toFile())) {
            out.getChannel().write(buffer);
            out.getFD().sync();
        }
        Files.move(tmpPath, dirPath.resolve(fileName), StandardCopyOption.ATOMIC_MOVE);
    }

    @Override
    public void purge(String fileName) throws IOException {
        Path path = dirPath.resolve(fileName);
        Files.delete(path);
    }

    // @return the head page checkpoint file name
    @Override
    public String headFileName() {
         return HEAD_CHECKPOINT;
    }

    // @return the tail page checkpoint file name for given page number
    @Override
    public String tailFileName(int pageNum) {
        return TAIL_CHECKPOINT + pageNum;
    }

    public static Checkpoint read(ByteBuffer data) throws IOException {
        int version = (int) data.getShort();
        // TODO - build reader for this version
        int pageNum = data.getInt();
        int firstUnackedPageNum = data.getInt();
        long firstUnackedSeqNum = data.getLong();
        long minSeqNum = data.getLong();
        int elementCount = data.getInt();
        final CRC32 crc32 = new CRC32();
        crc32.update(data.array(), 0, BUFFER_SIZE - Integer.BYTES);
        int calcCrc32 = (int) crc32.getValue();
        int readCrc32 = data.getInt();
        if (readCrc32 != calcCrc32) {
            throw new IOException(String.format("Checkpoint checksum mismatch, expected: %d, actual: %d", calcCrc32, readCrc32));
        }
        if (version != Checkpoint.VERSION) {
            throw new IOException("Unknown file format version: " + version);
        }

        return new Checkpoint(pageNum, firstUnackedPageNum, firstUnackedSeqNum, minSeqNum, elementCount);
    }

    private void write(Checkpoint checkpoint, ByteBuffer buf) {
        crc32.reset();
        buf.clear();
        buf.putShort((short)Checkpoint.VERSION);
        buf.putInt(checkpoint.getPageNum());
        buf.putInt(checkpoint.getFirstUnackedPageNum());
        buf.putLong(checkpoint.getFirstUnackedSeqNum());
        buf.putLong(checkpoint.getMinSeqNum());
        buf.putInt(checkpoint.getElementCount());
        buf.flip();
        crc32.update(buf);
        buf.position(BUFFER_SIZE - Integer.BYTES).limit(BUFFER_SIZE);
        buf.putInt((int)crc32.getValue());
    }
}

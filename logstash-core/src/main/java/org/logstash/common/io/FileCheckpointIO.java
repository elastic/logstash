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


    private final String dirPath;

    public FileCheckpointIO(String dirPath) throws IOException {
        this.dirPath = dirPath;
    }

    @Override
    public Checkpoint read(String fileName) throws IOException {
        Path path  = Paths.get(fileName); // TODO: integrate dirPath

        StreamInput si = new InputStreamStreamInput(Files.newInputStream(path));
        byte version = si.readByte();
        // TODO - build reader for this version
        if (version != Checkpoint.VERSION) {
            throw new IOException("Unknown file format version: " + version);
        }

        int pageNum = si.readInt();
        int firstUnackedPageNum = si.readInt();
        long firstUnackedSeqNum = si.readLong();
        long minSeqNum = si.readLong();
        int elementCount = si.readInt();

        return new Checkpoint(pageNum, firstUnackedPageNum, firstUnackedSeqNum, minSeqNum, elementCount);
    }

    @Override
    public void write(String fileName, int pageNum, int firstUnackedPageNum, long firstUnackedSeqNum, long minSeqNum, int elementCount) throws IOException {
        Checkpoint checkpoint = new Checkpoint(pageNum, firstUnackedPageNum, firstUnackedSeqNum, minSeqNum, elementCount);

        try {
            FileOutputStream fos = new FileOutputStream(fileName, false);
            write(checkpoint, fos.getChannel());
            fos.flush();
            fos.getFD().sync();
            fos.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private void write(Checkpoint checkpoint, FileChannel channel) throws IOException {
        byte[] buffer = new byte[Checkpoint.BUFFER_SIZE];
        final ByteArrayStreamOutput out = new ByteArrayStreamOutput(buffer);
        write(checkpoint, out);
        ByteBuffer buf = ByteBuffer.wrap(buffer);
        while(buf.hasRemaining()) {
            channel.write(buf);
        }
    }

    private void write(Checkpoint checkpoint, StreamOutput out) throws IOException {
        out.writeByte(Checkpoint.VERSION);
        out.writeInt(checkpoint.getPageNum());
        out.writeInt(checkpoint.getFirstUnackedPageNum());
        out.writeLong(checkpoint.getFirstUnackedSeqNum());
        out.writeLong(checkpoint.getMinSeqNum());
        out.writeInt(checkpoint.getElementCount());
    }
}

/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


package org.logstash.ackedqueue.io;

import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.zip.CRC32;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.ackedqueue.Checkpoint;
import org.logstash.util.ExponentialBackoff;


/**
 * File implementation for {@link CheckpointIO}
 * */
public class FileCheckpointIO implements CheckpointIO {
//    Checkpoint file structure
//
//    byte version;
//    int pageNum;
//    int firstUnackedPageNum;
//    long firstUnackedSeqNum;
//    long minSeqNum;
//    int elementCount;

    private static final Logger logger = LogManager.getLogger(FileCheckpointIO.class);

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

    private final boolean retry;

    private static final String HEAD_CHECKPOINT = "checkpoint.head";
    private static final String TAIL_CHECKPOINT = "checkpoint.";
    private final Path dirPath;
    private final ExponentialBackoff backoff;

    public FileCheckpointIO(Path dirPath) {
        this(dirPath, false);
    }

    public FileCheckpointIO(Path dirPath, boolean retry) {
        this.dirPath = dirPath;
        this.retry = retry;
        this.backoff = new ExponentialBackoff(3L);
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

        // Windows can have problem doing file move See: https://github.com/elastic/logstash/issues/12345
        // retry a couple of times to make it works. The first two runs has no break. The rest of reties are exponential backoff.
        final Path path = dirPath.resolve(fileName);
        try {
            Files.move(tmpPath, path, StandardCopyOption.ATOMIC_MOVE);
        } catch (IOException ex) {
            if (retry) {
                try {
                    logger.debug("CheckpointIO retry moving '{}' to '{}'", tmpPath, path);
                    backoff.retryable(() -> Files.move(tmpPath, path, StandardCopyOption.ATOMIC_MOVE));
                } catch (ExponentialBackoff.RetryException re) {
                    throw new IOException("Error writing checkpoint", re);
                }
            } else {
                logger.error("Error writing checkpoint without retry: " + ex);
                throw ex;
            }
        }
    }

    @Override
    public void purge(String fileName) throws IOException {
        Path path = dirPath.resolve(fileName);
        logger.debug("CheckpointIO deleting '{}'", path);
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

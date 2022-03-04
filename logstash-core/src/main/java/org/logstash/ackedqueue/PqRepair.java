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


package org.logstash.ackedqueue;

import java.io.File;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.ackedqueue.io.FileCheckpointIO;
import org.logstash.ackedqueue.io.MmapPageIOV1;
import org.logstash.ackedqueue.io.MmapPageIOV2;

/**
 * Tool that attempts to fix a broken PQ data directory.
 */
public final class PqRepair {

    private static final Logger LOGGER = LogManager.getLogger(PqRepair.class);

    private PqRepair() {
        // Utility Class
    }

    public static void main(final String... args) throws IOException {
        if (args.length == 0) {
            throw new IllegalArgumentException("No queue directory given.");
        }
        final Path pqRoot = Paths.get(args[0]);
        repair(pqRoot);
    }

    public static void repair(final Path path) throws IOException {
        if (!path.toFile().isDirectory()) {
            throw new IllegalArgumentException(
                String.format("Given PQ path %s is not a directory.", path)
            );
        }

        LOGGER.info("Start repairing queue dir: {}", path.toString());

        deleteTempCheckpoint(path);

        final Map<Integer, Path> pageFiles = new HashMap<>();
        try (final DirectoryStream<Path> pfs = Files.newDirectoryStream(path, "page.*")) {
            pfs.forEach(p -> pageFiles.put(
                Integer.parseInt(p.getFileName().toString().substring("page.".length())), p)
            );
        }
        final Map<Integer, Path> checkpointFiles = new HashMap<>();
        try (final DirectoryStream<Path> cpfs = Files.newDirectoryStream(path, "checkpoint.*")) {
            cpfs.forEach(
                c -> {
                    final String cpFilename = c.getFileName().toString();
                    if (!"checkpoint.head".equals(cpFilename)) {
                        checkpointFiles.put(
                            Integer.parseInt(cpFilename.substring("checkpoint.".length())), c
                        );
                    }
                }
            );
        }
        deleteFullyAcked(path, pageFiles, checkpointFiles);
        fixMissingPages(pageFiles, checkpointFiles);
        fixZeroSizePages(pageFiles, checkpointFiles);
        fixMissingCheckpoints(pageFiles, checkpointFiles);

        LOGGER.info("Repair is done");
    }

    private static void deleteTempCheckpoint(final Path root) throws IOException {
        try (final DirectoryStream<Path> cpTmp = Files.newDirectoryStream(root, "checkpoint.*.tmp")) {
            for (Path cpTmpPath: cpTmp) {
                LOGGER.info("Deleting temp checkpoint {}", cpTmpPath);
                Files.delete(cpTmpPath);
            }
        }
    }

    private static void deleteFullyAcked(final Path root, final Map<Integer, Path> pages,
        final Map<Integer, Path> checkpoints) throws IOException {
        final String headCpName = "checkpoint.head";
        final File headCheckpoint = root.resolve(headCpName).toFile();
        if (headCheckpoint.exists()) {
            final int lowestUnAcked = new FileCheckpointIO(root).read(headCpName)
                .getFirstUnackedPageNum();
            deleteFullyAcked(pages, lowestUnAcked, extractPagenums(pages));
            deleteFullyAcked(checkpoints, lowestUnAcked, extractPagenums(checkpoints));
        }
    }

    private static void deleteFullyAcked(final Map<Integer, Path> files,
        final int lowestUnAcked, final int[] knownPagenums) throws IOException {
        for (final int number : knownPagenums) {
            if (number < lowestUnAcked) {
                final Path file = files.remove(number);
                if (file != null) {
                    LOGGER.info("Deleting {} because it was fully acknowledged.", file);
                    Files.delete(file);
                }
            } else {
                break;
            }
        }
    }

    private static void fixMissingCheckpoints(final Map<Integer, Path> pages,
        final Map<Integer, Path> checkpoints) throws IOException {
        final int[] knownPagenums = extractPagenums(pages);
        for (int i = 0; i < knownPagenums.length - 1; i++) {
            final int number = knownPagenums[i];
            final Path cpPath = checkpoints.get(number);
            if (cpPath == null) {
                final Path page = pages.get(number);
                recreateCheckpoint(page, number);
            } else if (cpPath.toFile().length() != FileCheckpointIO.BUFFER_SIZE) {
                Files.delete(cpPath);
                recreateCheckpoint(pages.get(number), number);
            }
        }
    }

    private static void recreateCheckpoint(final Path pageFile, final int number)
        throws IOException {
        final ByteBuffer buffer = ByteBuffer.allocateDirect(
            MmapPageIOV2.SEQNUM_SIZE + MmapPageIOV2.LENGTH_SIZE
        );
        LOGGER.info("Recreating missing checkpoint for page {}", pageFile);
        try (final FileChannel page = FileChannel.open(pageFile)) {
            page.read(buffer);
            final byte version = buffer.get(0);
            if (version != MmapPageIOV1.VERSION_ONE && version != MmapPageIOV2.VERSION_TWO) {
                throw new IllegalStateException(
                    String.format(
                        "Pagefile %s contains version byte %d, this tool only supports versions 1 and 2.",
                        pageFile, version
                    )
                );
            }
            buffer.position(1);
            buffer.compact();
            page.read(buffer);
            final long firstSeqNum = buffer.getLong(0);
            final long maxSize = page.size();
            long position = page.position();
            position += (long) buffer.getInt(8) + (long) MmapPageIOV2.CHECKSUM_SIZE;
            int count = 1;
            while (position < maxSize - MmapPageIOV2.MIN_CAPACITY) {
                page.position(position);
                buffer.clear();
                page.read(buffer);
                position += (long) buffer.getInt(8) + (long) MmapPageIOV2.CHECKSUM_SIZE;
                ++count;
            }
            // Writing 0 for the first unacked page num is ok here, since this value is only
            // used by the head checkpoint
            new FileCheckpointIO(pageFile.getParent()).write(
                String.format("checkpoint.%d", number), number, 0, firstSeqNum,
                firstSeqNum,
                count
            );
        }
    }

    private static void fixMissingPages(final Map<Integer, Path> pages,
        final Map<Integer, Path> checkpoints) throws IOException {
        final int[] knownCpNums = extractPagenums(checkpoints);
        for (final int number : knownCpNums) {
            if (!pages.containsKey(number)) {
                final Path cpPath = checkpoints.remove(number);
                Files.delete(cpPath);
                LOGGER.info(
                    "Deleting checkpoint {} because it has no associated page", cpPath
                );
            }
        }
    }

    /**
     * Deletes all pages that are too small in size to hold at least one event and hence are
     * certainly corrupted as well as their associated checkpoints.
     * @param pages Pages
     * @param checkpoints Checkpoints
     * @throws IOException On Failure
     */
    private static void fixZeroSizePages(final Map<Integer, Path> pages,
        final Map<Integer, Path> checkpoints) throws IOException {
        final int[] knownPagenums = extractPagenums(pages);
        for (final int number : knownPagenums) {
            final Path pagePath = pages.get(number);
            if (pagePath.toFile().length() < (long) MmapPageIOV2.MIN_CAPACITY) {
                LOGGER.info("Deleting empty page found at {}", pagePath);
                Files.delete(pagePath);
                pages.remove(number);
                final Path cpPath = checkpoints.remove(number);
                if (cpPath != null) {
                    LOGGER.info(
                        "Deleting checkpoint {} because it has no associated page", cpPath
                    );
                    Files.delete(cpPath);
                }
            }
        }
    }

    private static int[] extractPagenums(final Map<Integer, Path> fileMap) {
        final int[] knownPagenums = fileMap.keySet().stream().mapToInt(Integer::intValue).toArray();
        Arrays.sort(knownPagenums);
        return knownPagenums;
    }
}

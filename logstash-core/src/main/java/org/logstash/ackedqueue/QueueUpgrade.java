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

import com.google.common.primitives.Ints;
import java.io.File;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.Collection;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.stream.StreamSupport;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.Event;
import org.logstash.ackedqueue.io.CheckpointIO;
import org.logstash.ackedqueue.io.FileCheckpointIO;
import org.logstash.ackedqueue.io.MmapPageIOV1;
import org.logstash.ackedqueue.io.MmapPageIOV2;
import org.logstash.ackedqueue.io.PageIO;

/**
 * Exposes the {@link #upgradeQueueDirectoryToV2} method upgrade old v1 queue disk format to the new v2
 * */
public final class QueueUpgrade {

    private static final Logger LOGGER = LogManager.getLogger(QueueUpgrade.class);

    private static final Pattern PAGE_NAME_PATTERN = Pattern.compile("page\\.\\d+");

    private QueueUpgrade() {
        // Utility Class.
    }

    public static void upgradeQueueDirectoryToV2(final Path path) throws IOException {
        final File upgradeFile = path.resolve(".queue-version").toFile();
        if (upgradeFile.exists()) {
            if (Ints.fromByteArray(Files.readAllBytes(upgradeFile.toPath())) != 2) {
                throw new IllegalStateException(
                    "Unexpected upgrade file contents found."
                );
            }
            LOGGER.debug("PQ version file with correct version information (v2) found.");
        } else {
            LOGGER.info("No PQ version file found, upgrading to PQ v2.");
            try (final DirectoryStream<Path> files = Files.newDirectoryStream(path)) {
                final Collection<File> pageFiles = StreamSupport.stream(
                    files.spliterator(), false
                ).filter(
                    file -> PAGE_NAME_PATTERN.matcher(file.getFileName().toString()).matches()
                ).map(Path::toFile).collect(Collectors.toList());
                final CheckpointIO cpIo = new FileCheckpointIO(path);
                pageFiles.forEach(p -> validatePageFile(path, cpIo, p));
                pageFiles.forEach(QueueUpgrade::setV2);
            }
            Files.write(upgradeFile.toPath(), Ints.toByteArray(2), StandardOpenOption.CREATE);
        }
    }

    private static void validatePageFile(final Path path, final CheckpointIO cpIo, final File v1PageFile) {
        final int num =
            Integer.parseInt(v1PageFile.getName().substring("page.".length()));
        try (final MmapPageIOV1 iov1 = new MmapPageIOV1(
            num, Ints.checkedCast(v1PageFile.length()), path
        )) {
            final Checkpoint cp = loadCheckpoint(path, cpIo, num);
            final int count = cp.getElementCount();
            final long minSeqNum = cp.getMinSeqNum();
            iov1.open(minSeqNum, count);
            for (int i = 0; i < count; ++i) {
                verifyEvent(iov1, minSeqNum + i);
            }
        } catch (final IOException ex) {
            throw new IllegalStateException(ex);
        }
    }

    private static void verifyEvent(final PageIO iov1, final long seqNum) {
        try {
            Event.deserialize(iov1.read(seqNum, 1).getElements().get(0));
        } catch (final IOException ex) {
            failValidation(ex);
        }
    }

    private static void setV2(final File v1PageFile) {
        try (final RandomAccessFile raf = new RandomAccessFile(v1PageFile, "rw")) {
            raf.seek(0L);
            raf.writeByte((int) MmapPageIOV2.VERSION_TWO);
        } catch (final IOException ex) {
            throw new IllegalStateException(ex);
        }
    }

    private static Checkpoint loadCheckpoint(final Path path, final CheckpointIO cpIo,
        final int num) throws IOException {
        final String cpFilename = cpIo.tailFileName(num);
        final Checkpoint cp;
        if (path.resolve(cpFilename).toFile().exists()) {
            cp = cpIo.read(cpFilename);
        } else {
            cp = cpIo.read("checkpoint.head");
            if (cp.getPageNum() != num) {
                throw new IllegalStateException(
                    String.format("No checkpoint file found for page %d", num)
                );
            }
        }
        return cp;
    }

    private static void failValidation(final Throwable ex) {
        LOGGER.error("Logstash was unable to upgrade your persistent queue data." +
            "Please either downgrade to your previous version of Logstash and fully drain " +
            "your persistent queue or delete your queue data.dir if you " +
            "don't need to retain the data currently in your queue.");
        throw new IllegalStateException(ex);
    }
}

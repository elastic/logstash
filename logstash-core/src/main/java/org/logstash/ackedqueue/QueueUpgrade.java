package org.logstash.ackedqueue;

import com.google.common.primitives.Ints;
import java.io.File;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.ArrayList;
import java.util.Collection;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.Event;
import org.logstash.ackedqueue.io.CheckpointIO;
import org.logstash.ackedqueue.io.FileCheckpointIO;
import org.logstash.ackedqueue.io.MmapPageIOV1;
import org.logstash.ackedqueue.io.MmapPageIOV2;

public final class QueueUpgrade {

    private static final Logger LOGGER = LogManager.getLogger(QueueUpgrade.class);

    private static final Pattern PAGE_NAME_PATTERN = Pattern.compile("page\\.\\d+");

    private QueueUpgrade() {
        // Utility Class.
    }

    public static void upgradeQueueDirectoryToV2(final Path path) throws IOException {
        final File upgradeFile = path.resolve(".queue-version").toFile();
        if (!upgradeFile.exists()) {
            LOGGER.info("No PQ version file found, upgrading to PQ v2.");
            try (final DirectoryStream<Path> files = Files.newDirectoryStream(path)) {
                final Collection<File> oldFiles = new ArrayList<>();
                files.forEach(file -> {
                    final Matcher matcher = PAGE_NAME_PATTERN.matcher(file.getFileName().toString());
                    if (matcher.matches()) {
                        oldFiles.add(file.toFile());
                    }
                });
                final CheckpointIO cpIo = new FileCheckpointIO(path);
                for (final File v1PageFile : oldFiles) {
                    final int num =
                        Integer.parseInt(v1PageFile.getName().substring("page.".length()));
                    try (final MmapPageIOV1 iov1 = new MmapPageIOV1(
                        num, Ints.checkedCast(v1PageFile.length()), path
                    )) {
                        final Checkpoint cp = cpIo.read(cpIo.tailFileName(num));
                        final int count = cp.getElementCount();
                        final long minSeqNum = cp.getMinSeqNum();
                        iov1.open(minSeqNum, count);
                        for (int i = 0; i < count; ++i) {
                            try {
                                Event.deserialize(
                                    iov1.read(minSeqNum + 1L, 1).getElements().get(0)
                                );
                            } catch (final IOException ex) {
                                throw new IllegalStateException(
                                    "Logstash was unable to upgrade your persistent queue." +
                                        "Please either downgrade to version 6.2.3 and fully drain " +
                                        "your persistent queue or delete your queue data.dir if you " +
                                        "don't need to retain the data currently in your queue.", ex
                                );
                            }
                        }
                    }
                }
                for (final File v1PageFile : oldFiles) {
                    try (final RandomAccessFile raf = new RandomAccessFile(v1PageFile, "rw")) {
                        raf.seek(0L);
                        raf.writeByte((int) MmapPageIOV2.VERSION_TWO);
                    }
                }
            } catch (final Exception ex) {
                throw new IllegalStateException("Queue upgrade to V2 failed.", ex);
            }
            Files.write(upgradeFile.toPath(), Ints.toByteArray(2), StandardOpenOption.CREATE);
        } else {
            if (Ints.fromByteArray(Files.readAllBytes(upgradeFile.toPath())) != 2) {
                throw new IllegalStateException(
                    "Unexpected upgrade file contents found."
                );
            }
            LOGGER.debug("PQ version file with correct version information (v2) found.");
        }
    }
}

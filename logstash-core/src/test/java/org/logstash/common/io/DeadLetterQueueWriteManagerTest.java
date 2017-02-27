package org.logstash.common.io;

import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;
import org.logstash.ackedqueue.StringElement;

import java.nio.channels.FileChannel;
import java.nio.channels.FileLock;
import java.nio.channels.OverlappingFileLockException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;

import static junit.framework.TestCase.assertFalse;
import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.CoreMatchers.nullValue;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;

public class DeadLetterQueueWriteManagerTest {
    private Path dir;

    @Rule
    public TemporaryFolder temporaryFolder = new TemporaryFolder();

    @Before
    public void setUp() throws Exception {
        dir = temporaryFolder.newFolder().toPath();
    }

    @Test
    public void testLockFileManagement() throws Exception {
        Path lockFile = dir.resolve(".lock");
        DeadLetterQueueWriteManager writer = new DeadLetterQueueWriteManager(dir, 1000, 1000000);
        assertTrue(Files.exists(lockFile));
        writer.close();
        assertFalse(Files.exists(lockFile));
    }

    @Test
    public void testFileLocking() throws Exception {
        DeadLetterQueueWriteManager writer = new DeadLetterQueueWriteManager(dir, 1000, 1000000);
        try {
            new DeadLetterQueueWriteManager(dir, 1000, 100000);
            fail();
        } catch (RuntimeException e) {
        } finally {
            writer.close();
        }
    }

    @Test
    public void testUncleanCloseOfPreviousWriter() throws Exception {
        Path lockFilePath = dir.resolve(".lock");
        boolean created = lockFilePath.toFile().createNewFile();
        DeadLetterQueueWriteManager writer = new DeadLetterQueueWriteManager(dir, 1000, 1000000);

        FileChannel channel = FileChannel.open(lockFilePath, StandardOpenOption.WRITE);
        try {
            channel.lock();
            fail();
        } catch (OverlappingFileLockException e) {
            assertTrue(created);
        } finally {
            writer.close();
        }
    }
}
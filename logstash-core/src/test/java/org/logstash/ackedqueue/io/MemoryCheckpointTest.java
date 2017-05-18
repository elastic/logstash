package org.logstash.ackedqueue.io;

import java.io.IOException;
import java.nio.file.NoSuchFileException;
import org.junit.Before;
import org.junit.Test;
import org.logstash.ackedqueue.Checkpoint;
import org.logstash.ackedqueue.SettingsImpl;
import org.logstash.ackedqueue.Settings;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;

public class MemoryCheckpointTest {

    private CheckpointIO io;

    @Before
    public void setUp() {
        CheckpointIOFactory factory = (dirPath) -> new MemoryCheckpointIO(dirPath);
        Settings settings = 
            SettingsImpl.memorySettingsBuilder().checkpointIOFactory(factory).build();
        this.io = settings.getCheckpointIOFactory().build(settings.getDirPath());
    }

    @Test
    public void writeNewReadExisting() throws IOException {
        io.write("checkpoint.head", 1, 2, 3, 4, 5);

        Checkpoint checkpoint = io.read("checkpoint.head");

        assertThat(checkpoint.getPageNum(), is(equalTo(1)));
        assertThat(checkpoint.getFirstUnackedPageNum(), is(equalTo(2)));
        assertThat(checkpoint.getFirstUnackedSeqNum(), is(equalTo(3L)));
        assertThat(checkpoint.getMinSeqNum(), is(equalTo(4L)));
        assertThat(checkpoint.getElementCount(), is(equalTo(5)));
    }

    @Test(expected = NoSuchFileException.class)
    public void readNonexistent() throws IOException {
        io.read("checkpoint.invalid");
    }

    @Test
    public void readWriteDirPathNamespaced() throws IOException {
        CheckpointIO io1 = new MemoryCheckpointIO("path1");
        CheckpointIO io2 = new MemoryCheckpointIO("path2");
        io1.write("checkpoint.head", 1, 0, 0, 0, 0);
        io2.write("checkpoint.head", 2, 0, 0, 0, 0);

        Checkpoint checkpoint;

        checkpoint = io1.read("checkpoint.head");
        assertThat(checkpoint.getPageNum(), is(equalTo(1)));

        checkpoint = io2.read("checkpoint.head");
        assertThat(checkpoint.getPageNum(), is(equalTo(2)));
    }

    @Test(expected = NoSuchFileException.class)
    public void purgeDirPathNamespaced1() throws IOException {
        CheckpointIO io1 = new MemoryCheckpointIO("path1");
        CheckpointIO io2 = new MemoryCheckpointIO("path2");
        io1.write("checkpoint.head", 1, 0, 0, 0, 0);
        io2.write("checkpoint.head", 2, 0, 0, 0, 0);

        io1.purge("checkpoint.head");

        Checkpoint checkpoint = io1.read("checkpoint.head");
    }

    @Test
    public void purgeDirPathNamespaced2() throws IOException {
        CheckpointIO io1 = new MemoryCheckpointIO("path1");
        CheckpointIO io2 = new MemoryCheckpointIO("path2");
        io1.write("checkpoint.head", 1, 0, 0, 0, 0);
        io2.write("checkpoint.head", 2, 0, 0, 0, 0);

        io1.purge("checkpoint.head");

        Checkpoint checkpoint;
        checkpoint = io2.read("checkpoint.head");
        assertThat(checkpoint.getPageNum(), is(equalTo(2)));
    }
}

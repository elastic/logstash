package org.logstash.common.io;

import org.junit.Before;
import org.junit.Test;
import static org.junit.Assert.fail;
import org.logstash.ackedqueue.Checkpoint;
import org.logstash.ackedqueue.MemorySettings;
import org.logstash.ackedqueue.Settings;

import java.io.IOException;
import java.nio.file.NoSuchFileException;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;

public class MemoryCheckpointTest {

    private CheckpointIO io;

    @Before
    public void setUp() {
        Settings settings = new MemorySettings();
        CheckpointIOFactory factory = (dirPath) -> new MemoryCheckpointIO(dirPath);
        settings.setCheckpointIOFactory(factory);
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
    public void readInnexisting() throws IOException {
        io.read("checkpoint.invalid");
    }
}

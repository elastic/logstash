package org.logstash.ackedqueue.io;

import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;
import org.logstash.ackedqueue.Checkpoint;

import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;

public class FileCheckpointIOTest {
    private Path checkpointFolder;
    private CheckpointIO io;

    @Rule
    public TemporaryFolder temporaryFolder = new TemporaryFolder();

    @Before
    public void setUp() throws Exception {
        checkpointFolder = temporaryFolder
            .newFolder("checkpoints")
            .toPath();
        io = new FileCheckpointIO(checkpointFolder);
    }

    @Test
    public void read() throws Exception {
        URL url = this.getClass().getResource("checkpoint.head");
        io = new FileCheckpointIO(Paths.get(url.toURI()).getParent());
        Checkpoint chk = io.read("checkpoint.head");
        assertThat(chk.getMinSeqNum(), is(8L));
    }

    @Test
    public void write() throws Exception {
        io.write("checkpoint.head", 6, 2, 10L, 8L, 200);
        io.write("checkpoint.head", 6, 2, 10L, 8L, 200);
        Path fullFileName = checkpointFolder.resolve("checkpoint.head");
        byte[] contents = Files.readAllBytes(fullFileName);
        URL url = this.getClass().getResource("checkpoint.head");
        Path path = Paths.get(url.toURI());
        byte[] compare = Files.readAllBytes(path);
        assertThat(contents, is(equalTo(compare)));
    }
}

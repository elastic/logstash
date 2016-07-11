package org.logstash.common.io;

import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;

import java.nio.file.Files;
import java.nio.file.Paths;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;

public class FileCheckpointIOTest {
    private String checkpointFolder;
    private CheckpointIO ckpio;

    @Rule
    public TemporaryFolder temporaryFolder = new TemporaryFolder();

    @Before
    public void setUp() throws Exception {
        checkpointFolder = temporaryFolder
                .newFolder("checkpoints")
                .getPath();
        ckpio = new FileCheckpointIO(checkpointFolder);
    }

    @Test
    public void read() throws Exception {

    }

    @Test
    public void write() throws Exception {
        String fullFileName = Paths.get(checkpointFolder, "checkpoint.head").toString();
        ckpio.write(fullFileName, 6, 2, 10L, 8L, 200);
        byte[] contents = Files.readAllBytes(Paths.get(fullFileName));
        assertThat(contents.length, is(equalTo(37)));
    }

}
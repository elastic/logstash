package org.logstash.ackedqueue.io;

import java.nio.file.Path;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;

import java.io.IOException;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;


public class MmapPageIOTest {
    @Rule
    public final TemporaryFolder temporaryFolder = new TemporaryFolder();

    private Path dir;

    @Before
    public void setUp() throws Exception {
        dir = temporaryFolder.newFolder().toPath();
    }

    @Test
    public void adjustToExistingCapacity() throws IOException {
        final int ORIGINAL_CAPACITY = 1024;
        final int NEW_CAPACITY = 2048;
        final int PAGE_NUM = 0;

        try (PageIO io1 = new MmapPageIOV2(PAGE_NUM, ORIGINAL_CAPACITY, dir)) {
            io1.create();
        }

        try (PageIO io2 = new MmapPageIOV2(PAGE_NUM, NEW_CAPACITY, dir)) {
            io2.open(0, PAGE_NUM);
            assertThat(io2.getCapacity(), is(equalTo(ORIGINAL_CAPACITY)));
        }
    }
}

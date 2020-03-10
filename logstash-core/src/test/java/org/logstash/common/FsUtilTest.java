package org.logstash.common;

import org.hamcrest.CoreMatchers;
import org.hamcrest.MatcherAssert;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;

/**
 * Tests for {@link FsUtil}.
 */
public final class FsUtilTest {

    @Rule
    public final TemporaryFolder temp = new TemporaryFolder();

    /**
     * {@link FsUtil#hasFreeSpace(java.nio.file.Path, long)} should return true when asked for 1kb of free
     * space in a subfolder of the system's TEMP location.
     */
    @Test
    public void trueIfEnoughSpace() throws Exception {
        MatcherAssert.assertThat(
                FsUtil.hasFreeSpace(temp.newFolder().toPath().toAbsolutePath(), 1024L),
                CoreMatchers.is(true)
        );
    }

    /**
     * {@link FsUtil#hasFreeSpace(java.nio.file.Path, long)} should return false when asked for
     * {@link Long#MAX_VALUE} of free space in a subfolder of the system's TEMP location.
     */
    @Test
    public void falseIfNotEnoughSpace() throws Exception {
        MatcherAssert.assertThat(
                FsUtil.hasFreeSpace(temp.newFolder().toPath().toAbsolutePath(), Long.MAX_VALUE),
                CoreMatchers.is(false)
        );
    }
}

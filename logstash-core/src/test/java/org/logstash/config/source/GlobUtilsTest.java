package org.logstash.config.source;

import org.junit.Test;

import java.nio.file.Path;
import java.nio.file.Paths;

import static org.junit.Assert.*;

public class GlobUtilsTest {

    @Test
    public void testSplitBaseAndGlobForAbsolutePlainPath() {
        final Path path = Paths.get("/tmp/sub/test.conf");

        final GlobUtils.BaseAndGlobPaths res = GlobUtils.splitBasePathAndGlobParts(path);

        assertEquals("/tmp/sub/test.conf", res.base().toString());
        assertEquals("glob:" + path.toString(), res.globPattern());
    }

    @Test
    public void testSplitOnAbsoluteDirectoryPath() {
        final Path path = Paths.get("/tmp/test-123/");

        final GlobUtils.BaseAndGlobPaths res = GlobUtils.splitBasePathAndGlobParts(path);

        assertEquals("/tmp/test-123", res.base().toString());
    }
}
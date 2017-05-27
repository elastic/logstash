package org.logstash.ingest;

import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;

public final class GrokTest {

    @Rule
    public final TemporaryFolder temp = new TemporaryFolder();

    @Test
    public void convertsCorrectly() throws Exception {
        final File testdir = temp.newFolder();
        final String grok = testdir.toPath().resolve("converted.grok").toString();
        Grok.main(resourcePath("ingestTestConfig.json"), grok);
        assertThat(
            utf8File(grok), is(utf8File(resourcePath("ingestTestConfig.grok")))
        );
    }

    private static String utf8File(final String path) throws IOException {
        return new String(Files.readAllBytes(Paths.get(path)), StandardCharsets.UTF_8);
    }

    private static String resourcePath(final String name) {
        return Grok.class.getResource(name).getPath();
    }
}

package org.logstash.ingest;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import org.apache.commons.io.IOUtils;
import org.junit.Rule;
import org.junit.rules.TemporaryFolder;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.junit.runners.Parameterized.Parameter;

/**
 * Base class for ingest migration tests
 */
@RunWith(Parameterized.class)
public abstract class IngestTest {

    @Rule
    public TemporaryFolder temp = new TemporaryFolder();

    @Parameter
    public String testCase;

    protected final void assertCorrectConversion(final Class clazz) throws Exception {
        final URL append = getResultPath(temp);
        clazz.getMethod("main", String[].class).invoke(
            null,
            (Object) new String[]{
                String.format("--input=%s", resourcePath(String.format("ingest%s.json", testCase))),
                String.format("--output=%s", append)
            }
        );
        assertThat(
            utf8File(append), is(utf8File(resourcePath(String.format("logstash%s.conf", testCase))))
        );
    }

    private static String utf8File(final URL path) throws IOException {
        final ByteArrayOutputStream baos = new ByteArrayOutputStream();
        try (final InputStream input = path.openStream()) {
            IOUtils.copy(input, baos);
        }
        return baos.toString(StandardCharsets.UTF_8.name());
    }

    private static URL resourcePath(final String name) {
        return IngestTest.class.getResource(name);
    }

    static URL getResultPath(TemporaryFolder temp) throws IOException {
        return temp.newFolder().toPath().resolve("converted").toUri().toURL();
    }
}

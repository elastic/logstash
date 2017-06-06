package org.logstash.ingest;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
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
        final String append = getResultPath(temp);
        clazz.getMethod("main", String[].class).invoke(
            null,
            (Object) new String[]{
                String.format("--input=file://%s", resourcePath(String.format("ingest%s.json", testCase))),
                String.format("--output=file://%s", append)
            }
        );
        assertThat(
            utf8File(append), is(utf8File(resourcePath(String.format("logstash%s.conf", testCase))))
        );
    } 
    
    static String utf8File(final String path) throws IOException {
        return new String(Files.readAllBytes(Paths.get(path)), StandardCharsets.UTF_8);
    }

    static String resourcePath(final String name) {
        return IngestTest.class.getResource(name).getPath();
    }

    static String getResultPath(TemporaryFolder temp) throws IOException {
        return temp.newFolder().toPath().resolve("converted").toString();
    }
}

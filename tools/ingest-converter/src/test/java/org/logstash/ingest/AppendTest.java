package org.logstash.ingest;

import java.util.Arrays;
import org.junit.Test;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.junit.runners.Parameterized.Parameters;

public final class AppendTest extends IngestTest {

    @Parameters
    public static Iterable<String> data() {
        return Arrays.asList("Append", "DotsInAppendField", "AppendScalar");
    }

    @Test
    public void convertsAppendProcessorCorrectly() throws Exception {
        final String append = getResultPath(temp);
        Append.main(resourcePath(String.format("ingest%s.json", testCase)), append);
        assertThat(
            utf8File(append), is(utf8File(resourcePath(String.format("logstash%s.conf", testCase))))
        );
    }
}

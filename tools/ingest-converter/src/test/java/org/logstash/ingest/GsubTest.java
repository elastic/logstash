package org.logstash.ingest;

import java.util.Collections;
import org.junit.Test;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.junit.runners.Parameterized.Parameters;

public final class GsubTest extends IngestTest {

    @Parameters
    public static Iterable<String> data() {
        return Collections.singletonList("GsubSimple");
    }

    @Test
    public void convertsGsubCorrectly() throws Exception {
        final String date = getResultPath(temp);
        Gsub.main(resourcePath(String.format("ingest%s.json", testCase)), date);
        assertThat(
            utf8File(date), is(utf8File(resourcePath(String.format("logstash%s.conf", testCase))))
        );
    }
}

package org.logstash.ingest;

import java.util.Arrays;
import org.junit.Test;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.junit.runners.Parameterized.Parameters;

public final class JsonTest extends IngestTest {

    @Parameters
    public static Iterable<String> data() {
        return Arrays.asList("Json", "DotsInJsonField", "JsonExtraFields");
    }

    @Test
    public void convertsConvertProcessorCorrectly() throws Exception {
        final String json = getResultPath(temp);
        Json.main(resourcePath(String.format("ingest%s.json", testCase)), json);
        assertThat(
            utf8File(json), is(utf8File(resourcePath(String.format("logstash%s.conf", testCase))))
        );
    }
}
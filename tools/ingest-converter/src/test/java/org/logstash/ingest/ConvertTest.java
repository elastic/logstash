package org.logstash.ingest;

import java.util.Arrays;
import org.junit.Test;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.junit.runners.Parameterized.Parameters;

public final class ConvertTest extends IngestTest {

    @Parameters
    public static Iterable<String> data() {
        return Arrays.asList("Convert", "DotsInConvertField", "ConvertBoolean", "ConvertString");
    }

    @Test
    public void convertsConvertProcessorCorrectly() throws Exception {
        final String convert = getResultPath(temp);
        Convert.main(resourcePath(String.format("ingest%s.json", testCase)), convert);
        assertThat(
            utf8File(convert), is(utf8File(resourcePath(String.format("logstash%s.conf", testCase))))
        );
    }
}

package org.logstash.ingest;

import java.util.Arrays;
import org.junit.Test;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.junit.runners.Parameterized.Parameters;

public final class RenameTest extends IngestTest {

    @Parameters
    public static Iterable<String> data() {
        return Arrays.asList("Rename", "DotsInRenameField");
    }

    @Test
    public void convertsConvertProcessorCorrectly() throws Exception {
        final String rename = getResultPath(temp);
        Rename.main(resourcePath(String.format("ingest%s.json", testCase)), rename);
        assertThat(
            utf8File(rename), is(utf8File(resourcePath(String.format("logstash%s.conf", testCase))))
        );
    }
}

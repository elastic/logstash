package org.logstash.ingest;

import java.util.Arrays;
import org.junit.Test;

import static org.junit.runners.Parameterized.Parameters;

public final class DateTest extends IngestTest {

    @Parameters
    public static Iterable<String> data() {
        return Arrays.asList("Date", "DateExtraFields", "DotsInDateField");
    }

    @Test
    public void convertsDateFieldCorrectly() throws Exception {
        assertCorrectConversion(Date.class);
    }
}

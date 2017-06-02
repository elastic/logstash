package org.logstash.ingest;

import org.junit.Test;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;

public final class DateTest extends IngestTest {

    @Test
    public void convertsFieldPatternsCorrectly() throws Exception {
        final String date = getResultPath(temp);
        Date.main(resourcePath("ingestDate.json"), date);
        assertThat(
            utf8File(date), is(utf8File(resourcePath("logstashDate.conf")))
        );
    }

    @Test
    public void convertsFieldDefinitionsCorrectly() throws Exception {
        final String date = getResultPath(temp);
        Date.main(resourcePath("ingestDateExtraFields.json"), date);
        assertThat(
            utf8File(date), is(utf8File(resourcePath("logstashDateExtraFields.conf")))
        );
    }
}

package org.logstash.ingest;

import org.junit.Test;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;

public final class GrokTest extends IngestTest {

    @Test
    public void convertsFieldPatternsCorrectly() throws Exception {
        final String grok = getResultPath(temp);
        Grok.main(resourcePath("ingestGrok.json"), grok);
        assertThat(
            utf8File(grok), is(utf8File(resourcePath("logstashGrok.conf")))
        );
    }

    @Test
    public void convertsFieldDefinitionsCorrectly() throws Exception {
        final String grok = getResultPath(temp);
        Grok.main(resourcePath("ingestGrokPatternDefinition.json"), grok);
        assertThat(
            utf8File(grok), is(utf8File(resourcePath("logstashGrokPatternDefinition.conf")))
        );
    }
}

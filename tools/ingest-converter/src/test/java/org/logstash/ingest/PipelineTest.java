package org.logstash.ingest;

import java.util.ArrayList;
import java.util.Collection;
import org.junit.Test;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.junit.runners.Parameterized.Parameters;

public final class PipelineTest extends IngestTest {

    @Parameters
    public static Iterable<String> data() {
        final Collection<String> cases = new ArrayList<>();
        cases.add("ComplexCase1");
        cases.add("ComplexCase2");
        GeoIpTest.data().forEach(cases::add);
        DateTest.data().forEach(cases::add);
        GrokTest.data().forEach(cases::add);
        ConvertTest.data().forEach(cases::add);
        GsubTest.data().forEach(cases::add);
        return cases;
    }

    @Test
    public void convertsComplexCaseCorrectly() throws Exception {
        final String date = getResultPath(temp);
        Pipeline.main(resourcePath(String.format("ingest%s.json", testCase)), date);
        assertThat(
            utf8File(date), is(utf8File(resourcePath(String.format("logstash%s.conf", testCase))))
        );
    }
}

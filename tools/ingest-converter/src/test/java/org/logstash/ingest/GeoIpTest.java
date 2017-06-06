package org.logstash.ingest;

import java.util.Arrays;
import org.junit.Test;

import static org.junit.runners.Parameterized.Parameters;

public final class GeoIpTest extends IngestTest {

    @Parameters
    public static Iterable<String> data() {
        return Arrays.asList("GeoIpSimple", "DotsInGeoIpField");
    }

    @Test
    public void convertsGeoIpFieldCorrectly() throws Exception {
        assertCorrectConversion(GeoIp.class);
    }
}

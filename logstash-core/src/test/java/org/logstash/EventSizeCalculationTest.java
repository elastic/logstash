package org.logstash;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.sun.management.HotSpotDiagnosticMXBean;
import org.jruby.java.proxies.ConcreteJavaProxy;
import org.junit.Test;
import org.openjdk.jol.info.GraphLayout;

import javax.management.MBeanServer;
import java.io.IOException;
import java.lang.management.ManagementFactory;
import java.math.BigDecimal;
import java.math.BigInteger;
import java.math.RoundingMode;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

/*
* Run with: ./gradlew :logstash-core:rubyTests --tests "org.logstash.EventSizeCalculationTest.compareDeeplyNestedEventSizeComputation" -Dorg.gradle.jvmargs=-Xmx4g
* */

public final class EventSizeCalculationTest extends RubyTestBase {

    public static final String SHORT_FILLING_STRING = "Test string";
    // 512 bytes
    public static final String MEDIUM_FILLING_STRING = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum Excepteur sint occaecat cupidatat non proident, sunt in culpa quioe";

    //2048 bytes
    public static final String LONG_FILLING_STRING = MEDIUM_FILLING_STRING + MEDIUM_FILLING_STRING + MEDIUM_FILLING_STRING + MEDIUM_FILLING_STRING;

    private final static class EventAndSize {
        final Event event;
        final long size;

        private EventAndSize(Event event, long size) {
            this.event = event;
            this.size = size;
        }
    }

    private final static class SizeReport {
        final long raw;
        final long mapEstimated;
        final long cbor;
        final long jol;

        private SizeReport(long raw, long mapEstimated, long cbor, long jol) {
            this.raw = raw;
            this.mapEstimated = mapEstimated;
            this.cbor = cbor;
            this.jol = jol;
        }
    }

    @Test
    public void compareAlmostRealisticEventSizeComputation() throws Exception {
        Map<String, SizeReport> reports = new HashMap<>();
        EventAndSize es = createTestEvent(Paths.get("test_events_json/apache_1KB.json"));
        captureHeapDump("event_with_apache1KB.hprof");
        reports.put("apache 1KB", reportSizes(es));

        es = createTestEvent(Paths.get("test_events_json/apache_2KB.json"));
        captureHeapDump("event_with_apache2KB.hprof");
        reports.put("apache 2KB", reportSizes(es));

        es = createTestEvent(Paths.get("test_events_json/apache_4KB.json"));
        captureHeapDump("event_with_apache4KB.hprof");
        reports.put("apache 4KB", reportSizes(es));

        es = createTestEvent(Paths.get("test_events_json/cloudTrail_1KB.json"));
        captureHeapDump("event_with_cloudTrail1KB.hprof");
        reports.put("cloudTrail 1KB", reportSizes(es));

        es = createTestEvent(Paths.get("test_events_json/cloudTrail_2KB.json"));
        captureHeapDump("event_with_cloudTrail2KB.hprof");
        reports.put("cloudTrail 2KB", reportSizes(es));

        es = createTestEvent(Paths.get("test_events_json/cloudTrail_4KB.json"));
        captureHeapDump("event_with_cloudTrail4KB.hprof");
        reports.put("cloudTrail 4KB", reportSizes(es));

        es = createTestEvent(Paths.get("test_events_json/snmp_1KB.json"));
        captureHeapDump("event_with_snmp1KB.hprof");
        reports.put("snmp 1KB", reportSizes(es));

        es = createTestEvent(Paths.get("test_events_json/snmp_2KB.json"));
        captureHeapDump("event_with_snmp2KB.hprof");
        reports.put("snmp 2KB", reportSizes(es));

        es = createTestEvent(Paths.get("test_events_json/snmp_4KB.json"));
        captureHeapDump("event_with_snmp4KB.hprof");
        reports.put("snmp 4KB", reportSizes(es));

        printReport(reports);
    }

    private void printReport(Map<String, SizeReport> reports) {
        System.out.println("| testName |  raw | map navigation |  cbor  | jol (retained)|");
        System.out.println("|----------|------|----------------|--------|---------------|");
        reports.entrySet().stream().sorted(Map.Entry.comparingByKey()).forEach(entry -> {
            String testName = entry.getKey();
            SizeReport report = entry.getValue();
            String estimatedDelta = gainLossAgainstRawSize(report, report.mapEstimated);
            String cborDelta = gainLossAgainstRawSize(report, report.cbor);

            System.out.println("|" + testName + "|" + report.raw + "|" + report.mapEstimated + "(" + estimatedDelta + ")|" + report.cbor + "(" + cborDelta + ")|" + report.jol + "|");
        });
    }

    private static String gainLossAgainstRawSize(SizeReport report, long value) {
        double estimatedDelta = (double)(value - report.raw) / report.raw;
        BigDecimal bd = new BigDecimal(estimatedDelta * 100)
                .setScale(2, RoundingMode.HALF_UP);

        return bd.toPlainString() + "%";
    }

    private static SizeReport reportSizes(EventAndSize es) throws JsonProcessingException {
        byte[] cborSerialized = es.event.serialize();
        long roughBytesEstimatedSize = es.event.estimateMemory();
        long jolSize = GraphLayout.parseInstance(es.event).totalSize();
        return new SizeReport(es.size, roughBytesEstimatedSize, cborSerialized.length, jolSize);
    }

    @SuppressWarnings("unchecked")
    private EventAndSize createTestEvent(Path jsonEventTemplateFile) throws IOException {
        byte[] content = Files.readAllBytes(jsonEventTemplateFile);
        String jsonContent = new String(content, StandardCharsets.UTF_8);
        Map<String, Object> jsonEvent = ObjectMappers.JSON_MAPPER.readValue(jsonContent, Map.class);
        Event event = new Event(jsonEvent);
        event.setField("timestamp", new Timestamp());

        return new EventAndSize(event, content.length);
    }

    @Test
    public void compareDeeplyNestedEventSizeComputation() throws Exception {
        long maxHeapBytes = Runtime.getRuntime().maxMemory();
        long maxHeapMB = maxHeapBytes / (1024 * 1024);

        System.out.printf("Max Heap Size: %d MB%n", maxHeapMB);

        System.out.println("Short string filling");
        Event event = createNestedEvent(10, 5, SHORT_FILLING_STRING);
        captureHeapDump("event_with_short_string.hprof");
        reportSizes(event);

        System.out.println("Medium string filling");
        event = createNestedEvent(10, 5, MEDIUM_FILLING_STRING);
        captureHeapDump("event_with_medium_string.hprof");
        reportSizes(event);

        System.out.println("Long string filling");
        event = createNestedEvent(10, 5, LONG_FILLING_STRING);
        captureHeapDump("event_with_long_string.hprof");
        reportSizes(event);

        System.out.println("Long string filling no ddep nesting");
        event = createNestedEvent(10, 1, LONG_FILLING_STRING);
        captureHeapDump("event_with_long_string_no_deep.hprof");
        reportSizes(event);
    }

    private static void reportSizes(Event e) throws JsonProcessingException {
        byte[] cborSerialized = e.serialize();
        long roughBytesEstimatedSize = e.estimateMemory();
        long jolSize = GraphLayout.parseInstance(e).totalSize();

        System.out.println("Calculated object size: " + roughBytesEstimatedSize + " bytes, CBOR size: " + cborSerialized.length + " JOL size: " + jolSize);
    }

    private Event createTestEvent() {
        // TODO fill with nested layers
        Event event = new Event();

        event.setField("timestamp", new ConcreteJavaProxy(RubyUtil.RUBY,
                RubyUtil.RUBY_TIMESTAMP_CLASS, new Timestamp()
        ));

        event.setField("[@metadata][foo]", Collections.emptyMap());
        event.setField("[@metadata][bar]", Collections.singletonList("hello"));

        // non ASCII
        event.setField("foo", "bör");

        final BigInteger bi = new BigInteger("9223372036854776000");
        final BigDecimal bd =  new BigDecimal("9223372036854776001.99");
        event.setField("bi", bi);
        event.setField("bd", bd);

        return event;
    }


    private static Event createNestedEvent(int elementsPerLayer, int layer, String fillingString) {
        double totalElements = Math.pow(elementsPerLayer, layer);
        System.out.println("Total elements: " + totalElements);

        // TODO fill with nested layers
        Event event = new Event();
        event.setField("timestamp", new ConcreteJavaProxy(RubyUtil.RUBY,
                RubyUtil.RUBY_TIMESTAMP_CLASS, new Timestamp()
        ));


        Map<String, Object> map = createSubdocument(elementsPerLayer, layer, fillingString);
        event.setField("custom_data", map);
        return event;
    }

    private static Map<String, Object> createSubdocument(int elementsPerLayer, int layer, String fillingString) {
        Map<String, Object> map = new HashMap<>(elementsPerLayer);
        for (int i = 0; i < elementsPerLayer; i++) {
            if (layer == 0) {
                map.put(String.format("field_%d", i), fillingString);
            } else {
                map.put(String.format("field_%d", i), createSubdocument(elementsPerLayer, layer - 1, fillingString));
            }
        }
        return map;
    }

    private void captureHeapDump(String dumpPath) throws IOException {
        MBeanServer server = ManagementFactory.getPlatformMBeanServer();
        HotSpotDiagnosticMXBean mxBean = ManagementFactory.newPlatformMXBeanProxy(
                server, "com.sun.management:type=HotSpotDiagnostic", HotSpotDiagnosticMXBean.class);
        mxBean.dumpHeap(dumpPath, true);
    }
}

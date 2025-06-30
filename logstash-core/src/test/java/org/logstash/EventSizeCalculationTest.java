package org.logstash;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.sun.management.HotSpotDiagnosticMXBean;
import org.jruby.java.proxies.ConcreteJavaProxy;
import org.junit.Test;

import javax.management.MBeanServer;
import java.io.IOException;
import java.lang.management.ManagementFactory;
import java.math.BigDecimal;
import java.math.BigInteger;
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

    @Test
    public void compareDeeplyNestedEventSizeComputation() throws Exception {
//        final Event e = createTestEvent();

//        ClassLayout classLayout = ClassLayout.parseInstance(e);
//        System.out.println("Calculated object size: " + classLayout.instanceSize() + " bytes, CBOR size: " + cborSerialized.length);
//        System.out.println(ClassLayout.parseInstance(e).toPrintable());
//        long roughBytesEstimatedSize = eventWithSize.size;
//        System.out.println("System -Djol.magicFieldOffset: " + System.getProperty("jol.magicFieldOffset"));
//        System.out.println("System -Djdk.attach.allowAttachSelf: " + System.getProperty("jdk.attach.allowAttachSelf"));
//        System.setProperty("jol.magicFieldOffset", "true");

        long maxHeapBytes = Runtime.getRuntime().maxMemory();
        long maxHeapMB = maxHeapBytes / (1024 * 1024);

        System.out.printf("Max Heap Size: %d MB%n", maxHeapMB);

        System.out.println("Short string filling");
        Event event = createNestedEvent(10, 5, SHORT_FILLING_STRING);
        captureHeapDump("event_with_short_string.hprof");
//        ClassLayout classLayout = ClassLayout.parseInstance(event).instanceSize();
//        String footprint = GraphLayout.parseInstance(event).toFootprint();
//        System.out.println(footprint);
//        System.out.println(GraphLayout.parseInstance(event).toPrintable());
        reportSizes(event);

        System.out.println("Medium string filling");
        event = createNestedEvent(10, 5, MEDIUM_FILLING_STRING);
        captureHeapDump("event_with_medium_string.hprof");
        reportSizes(event);

        System.out.println("Long string filling");
        event = createNestedEvent(10, 5, LONG_FILLING_STRING);
        captureHeapDump("event_with_long_string.hprof");
        reportSizes(event);
    }

    private static void reportSizes(Event e) throws JsonProcessingException {
        byte[] cborSerialized = e.serialize();
        long roughBytesEstimatedSize = e.estimateMemory();

        System.out.println("Calculated object size: " + roughBytesEstimatedSize + " bytes, CBOR size: " + cborSerialized.length);
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

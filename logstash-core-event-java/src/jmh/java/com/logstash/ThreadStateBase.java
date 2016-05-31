package com.logstash;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;

public abstract class ThreadStateBase {
    private static long execution_count = Long.valueOf(123456);
    private static BigDecimal customer_charge = BigDecimal.valueOf(12.6667);
    private static String customer_price_plan = "3245v6ih5v62h5v6hv667bv858vvu5683lhu358";

    public static Event event(){
        return new Event(new HashMap<String, Object>());
    }

    protected static void decorateEventRandomly(Event event) {
        Timestamp t = new Timestamp(EventSerializeBenchmark.Randomizer.nextEpoch());
        event.setField(ref(), EventSerializeBenchmark.Randomizer.nextLong());
        event.setField(ref(), EventSerializeBenchmark.Randomizer.nextBigDecimal());
        event.setField(ref(), EventSerializeBenchmark.Randomizer.nextBigInteger());
        event.setField(mref(), EventSerializeBenchmark.Randomizer.nextString());
        event.setField(Event.TIMESTAMP, t);
        event.cancel();
    }

    protected static Map buildRandomMap(Map<String, Object> meta) {
        Map data = new HashMap();
        data.put(EventSerializeBenchmark.Randomizer.nextString(), EventSerializeBenchmark.Randomizer.nextInt());
        data.put(EventSerializeBenchmark.Randomizer.nextString(), EventSerializeBenchmark.Randomizer.nextString());
        data.put(EventSerializeBenchmark.Randomizer.nextString(), EventSerializeBenchmark.Randomizer.nextDouble());
        data.put(Event.METADATA, meta);
        return data;
    }

    protected static void decorateEventTypically(Event event) {
        Timestamp t = new Timestamp(EventSerializeBenchmark.Randomizer.nextEpoch());
        event.setField("execution_count", execution_count);
        event.setField("customer_charge", customer_charge);
        event.setField("customer_id", EventSerializeBenchmark.Randomizer.nextBigInteger());
        event.setField("customer_price_plan", customer_price_plan);
        event.setField(Event.TIMESTAMP, t);
        event.cancel();
    }

    protected static Map buildTypicalMap(Map<String, Object> meta) {
        Map data = buildSizedMap(8);
        data.put("port", 6667);
        data.put("execution_time", 42.24);
        data.put("execution_unit", "ms");
        if (meta != null) data.put(Event.METADATA, meta);
        return data;
    }
    protected static Map buildMediumMap(Map<String, Object> meta) {
        Map data = buildSizedMap(80);
        data.put("port", 9900);
        data.put("execution_time", 678.24);
        data.put("execution_unit", "ms");
        if (meta != null) data.put(Event.METADATA, meta);
        return data;
    }

    protected static Map buildLargeMap(Map<String, Object> meta) {
        Map data = buildSizedMap(800);
        data.put("port", 9678);
        data.put("execution_time", 705.24);
        data.put("execution_unit", "ms");
        if (meta != null) data.put(Event.METADATA, meta);
        return data;
    }

    protected static Map buildExtraLargeMap(Map<String, Object> meta) {
        Map data = buildSizedMap(8000);
        data.put("port", 9909);
        data.put("execution_time", 0.705);
        data.put("execution_unit", "s");
        if (meta != null) data.put(Event.METADATA, meta);
        return data;
    }

    protected static Map buildSizedMap(int size) {
        Map data = new HashMap();
        if (size == 1) {
            data.put("message", EventSerializeBenchmark.Randomizer.nextBigString());
        } else {
            data.put("message", largeString(size));
        }
        return data;
    }

    private static String ref() {
        return "[" + EventSerializeBenchmark.Randomizer.nextString() + "]";
    }

    private static String mref() {
        return "[@metadata][" + EventSerializeBenchmark.Randomizer.nextString() + "]";
    }

    private static String largeString(int count){
        StringBuilder sb = new StringBuilder(26 * count);
        String repeat = EventSerializeBenchmark.Randomizer.nextString();
        for (int i = 0; i < count; i++) {
            sb.append(repeat);
        }
        return sb.toString();
    }
}

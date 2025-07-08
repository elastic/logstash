package org.logstash.benchmark;

import com.fasterxml.jackson.core.JsonProcessingException;
import org.logstash.Event;
import org.logstash.ObjectMappers;
import org.logstash.Timestamp;
import org.openjdk.jmh.annotations.*;
import org.openjdk.jmh.infra.Blackhole;
import org.openjdk.jol.info.GraphLayout;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Map;
import java.util.concurrent.TimeUnit;

/*
* ./gradlew jmh -Pinclude="org.logstash.benchmark.EventSizeEstimationUsingRealEventsBenchmark.*"
* */

@Warmup(iterations = 3, time = 100, timeUnit = TimeUnit.MILLISECONDS)
@Measurement(iterations = 10, time = 3, timeUnit = TimeUnit.SECONDS)
@Fork(1)
@BenchmarkMode(Mode.Throughput)
@OutputTimeUnit(TimeUnit.MILLISECONDS)
@State(Scope.Benchmark)
public class EventSizeEstimationUsingRealEventsBenchmark {

    private Event apache1KBEvent;
    private Event apache2KBEvent;
    private Event apache4KBEvent;
    private Event cloudTrail1KBEvent;
    private Event cloudTrail2KBEvent;
    private Event cloudTrail4KBEvent;
    private Event snmp1KBEvent;
    private Event snmp2KBEvent;
    private Event snmp4KBEvent;
    private Event apache16KBEvent;
    private Event apache32KBEvent;
    private Event apache128KBEvent;
    private Event cloudTrail16KBEvent;
    private Event cloudTrail32KBEvent;
    private Event cloudTrail128KBEvent;
    private Event snmp16KBEvent;
    private Event snmp32KBEvent;
    private Event snmp128KBEvent;

    @Setup(Level.Trial)
    public void setUp() throws IOException {
        apache1KBEvent = createTestEvent(Paths.get("../test_events_json/apache_1KB.json"));
        apache2KBEvent = createTestEvent(Paths.get("../test_events_json/apache_2KB.json"));
        apache4KBEvent = createTestEvent(Paths.get("../test_events_json/apache_4KB.json"));
        apache16KBEvent = createTestEvent(Paths.get("../test_events_json/apache_16KB.json"));
        apache32KBEvent = createTestEvent(Paths.get("../test_events_json/apache_32KB.json"));
        apache128KBEvent = createTestEvent(Paths.get("../test_events_json/apache_128KB.json"));

        cloudTrail1KBEvent = createTestEvent(Paths.get("../test_events_json/cloudtrail_1KB.json"));
        cloudTrail2KBEvent = createTestEvent(Paths.get("../test_events_json/cloudtrail_2KB.json"));
        cloudTrail4KBEvent = createTestEvent(Paths.get("../test_events_json/cloudtrail_4KB.json"));
        cloudTrail16KBEvent = createTestEvent(Paths.get("../test_events_json/cloudtrail_16KB.json"));
        cloudTrail32KBEvent = createTestEvent(Paths.get("../test_events_json/cloudtrail_32KB.json"));
        cloudTrail128KBEvent = createTestEvent(Paths.get("../test_events_json/cloudtrail_128KB.json"));

        snmp1KBEvent = createTestEvent(Paths.get("../test_events_json/snmp_1KB.json"));
        snmp2KBEvent = createTestEvent(Paths.get("../test_events_json/snmp_2KB.json"));
        snmp4KBEvent = createTestEvent(Paths.get("../test_events_json/snmp_4KB.json"));
        snmp16KBEvent = createTestEvent(Paths.get("../test_events_json/snmp_16KB.json"));
        snmp32KBEvent = createTestEvent(Paths.get("../test_events_json/snmp_32KB.json"));
        snmp128KBEvent = createTestEvent(Paths.get("../test_events_json/snmp_128KB.json"));
    }

    @SuppressWarnings("unchecked")
    private Event createTestEvent(Path jsonEventTemplateFile) throws IOException {
        byte[] content = Files.readAllBytes(jsonEventTemplateFile);
        String jsonContent = new String(content, StandardCharsets.UTF_8);
        Map<String, Object> jsonEvent = ObjectMappers.JSON_MAPPER.readValue(jsonContent, Map.class);
        Event event = new Event(jsonEvent);
        event.setField("timestamp", new Timestamp());

        return event;
    }

    @Benchmark
    public final void apache1KBConvertedMapNavigation(Blackhole blackhole) {
        long size = apache1KBEvent.estimateMemory();
        blackhole.consume(size);
    }

    @Benchmark
    public final void apache1KBCborSerialization(Blackhole blackhole) throws JsonProcessingException {
        byte[] cborSerialized = apache1KBEvent.serialize();
        blackhole.consume(cborSerialized);
    }

    @OutputTimeUnit(TimeUnit.SECONDS)
    @Benchmark
    public final void apache1KBJOLEstimation(Blackhole blackhole) throws JsonProcessingException {
        long jolSize = GraphLayout.parseInstance(apache1KBEvent).totalSize();
        blackhole.consume(jolSize);
    }

    @Benchmark
    public final void apache2KBConvertedMapNavigation(Blackhole blackhole) {
        long size = apache2KBEvent.estimateMemory();
        blackhole.consume(size);
    }

    @Benchmark
    public final void apache2KBCborSerialization(Blackhole blackhole) throws JsonProcessingException {
        byte[] cborSerialized = apache2KBEvent.serialize();
        blackhole.consume(cborSerialized);
    }

    @OutputTimeUnit(TimeUnit.SECONDS)
    @Benchmark
    public final void apache2KBJOLEstimation(Blackhole blackhole) throws JsonProcessingException {
        long jolSize = GraphLayout.parseInstance(apache2KBEvent).totalSize();
        blackhole.consume(jolSize);
    }

    @Benchmark
    public final void apache4KBConvertedMapNavigation(Blackhole blackhole) {
        long size = apache4KBEvent.estimateMemory();
        blackhole.consume(size);
    }

    @Benchmark
    public final void apache4KBCborSerialization(Blackhole blackhole) throws JsonProcessingException {
        byte[] cborSerialized = apache4KBEvent.serialize();
        blackhole.consume(cborSerialized);
    }

    @OutputTimeUnit(TimeUnit.SECONDS)
    @Benchmark
    public final void apache4KBJOLEstimation(Blackhole blackhole) throws JsonProcessingException {
        long jolSize = GraphLayout.parseInstance(apache4KBEvent).totalSize();
        blackhole.consume(jolSize);
    }

    @Benchmark
    public final void apache16KBConvertedMapNavigation(Blackhole blackhole) {
        long size = apache16KBEvent.estimateMemory();
        blackhole.consume(size);
    }

    @Benchmark
    public final void apache16KBCborSerialization(Blackhole blackhole) throws JsonProcessingException {
        byte[] cborSerialized = apache16KBEvent.serialize();
        blackhole.consume(cborSerialized);
    }

    @OutputTimeUnit(TimeUnit.SECONDS)
    @Benchmark
    public final void apache16KBJOLEstimation(Blackhole blackhole) throws JsonProcessingException {
        long jolSize = GraphLayout.parseInstance(apache16KBEvent).totalSize();
        blackhole.consume(jolSize);
    }

    @Benchmark
    public final void apache32KBConvertedMapNavigation(Blackhole blackhole) {
        long size = apache32KBEvent.estimateMemory();
        blackhole.consume(size);
    }

    @Benchmark
    public final void apache32KBCborSerialization(Blackhole blackhole) throws JsonProcessingException {
        byte[] cborSerialized = apache32KBEvent.serialize();
        blackhole.consume(cborSerialized);
    }

    @OutputTimeUnit(TimeUnit.SECONDS)
    @Benchmark
    public final void apache32KBJOLEstimation(Blackhole blackhole) throws JsonProcessingException {
        long jolSize = GraphLayout.parseInstance(apache32KBEvent).totalSize();
        blackhole.consume(jolSize);
    }

    @Benchmark
    public final void apache128KBConvertedMapNavigation(Blackhole blackhole) {
        long size = apache128KBEvent.estimateMemory();
        blackhole.consume(size);
    }

    @Benchmark
    public final void apache128KBCborSerialization(Blackhole blackhole) throws JsonProcessingException {
        byte[] cborSerialized = apache128KBEvent.serialize();
        blackhole.consume(cborSerialized);
    }

    @OutputTimeUnit(TimeUnit.SECONDS)
    @Benchmark
    public final void apache128KBJOLEstimation(Blackhole blackhole) throws JsonProcessingException {
        long jolSize = GraphLayout.parseInstance(apache128KBEvent).totalSize();
        blackhole.consume(jolSize);
    }

    @Benchmark
    public final void cloudTrail1KBConvertedMapNavigation(Blackhole blackhole) {
        long size = cloudTrail1KBEvent.estimateMemory();
        blackhole.consume(size);
    }

    @Benchmark
    public final void cloudTrail1KBCborSerialization(Blackhole blackhole) throws JsonProcessingException {
        byte[] cborSerialized = cloudTrail1KBEvent.serialize();
        blackhole.consume(cborSerialized);
    }

    @OutputTimeUnit(TimeUnit.SECONDS)
    @Benchmark
    public final void cloudTrail1KBJOLEstimation(Blackhole blackhole) throws JsonProcessingException {
        long jolSize = GraphLayout.parseInstance(cloudTrail1KBEvent).totalSize();
        blackhole.consume(jolSize);
    }

    @Benchmark
    public final void cloudTrail2KBConvertedMapNavigation(Blackhole blackhole) {
        long size = cloudTrail2KBEvent.estimateMemory();
        blackhole.consume(size);
    }

    @Benchmark
    public final void cloudTrail2KBCborSerialization(Blackhole blackhole) throws JsonProcessingException {
        byte[] cborSerialized = cloudTrail2KBEvent.serialize();
        blackhole.consume(cborSerialized);
    }

    @OutputTimeUnit(TimeUnit.SECONDS)
    @Benchmark
    public final void cloudTrail2KBJOLEstimation(Blackhole blackhole) throws JsonProcessingException {
        long jolSize = GraphLayout.parseInstance(cloudTrail2KBEvent).totalSize();
        blackhole.consume(jolSize);
    }

    @Benchmark
    public final void cloudTrail4KBConvertedMapNavigation(Blackhole blackhole) {
        long size = cloudTrail4KBEvent.estimateMemory();
        blackhole.consume(size);
    }

    @Benchmark
    public final void cloudTrail4KBCborSerialization(Blackhole blackhole) throws JsonProcessingException {
        byte[] cborSerialized = cloudTrail4KBEvent.serialize();
        blackhole.consume(cborSerialized);
    }

    @OutputTimeUnit(TimeUnit.SECONDS)
    @Benchmark
    public final void cloudTrail4KBJOLEstimation(Blackhole blackhole) throws JsonProcessingException {
        long jolSize = GraphLayout.parseInstance(cloudTrail4KBEvent).totalSize();
        blackhole.consume(jolSize);
    }

    @Benchmark
    public final void cloudTrail16KBConvertedMapNavigation(Blackhole blackhole) {
        long size = cloudTrail16KBEvent.estimateMemory();
        blackhole.consume(size);
    }

    @Benchmark
    public final void cloudTrail16KBCborSerialization(Blackhole blackhole) throws JsonProcessingException {
        byte[] cborSerialized = cloudTrail16KBEvent.serialize();
        blackhole.consume(cborSerialized);
    }

    @OutputTimeUnit(TimeUnit.SECONDS)
    @Benchmark
    public final void cloudTrail16KBJOLEstimation(Blackhole blackhole) throws JsonProcessingException {
        long jolSize = GraphLayout.parseInstance(cloudTrail16KBEvent).totalSize();
        blackhole.consume(jolSize);
    }

    @Benchmark
    public final void cloudTrail32KBConvertedMapNavigation(Blackhole blackhole) {
        long size = cloudTrail32KBEvent.estimateMemory();
        blackhole.consume(size);
    }

    @Benchmark
    public final void cloudTrail32KBCborSerialization(Blackhole blackhole) throws JsonProcessingException {
        byte[] cborSerialized = cloudTrail32KBEvent.serialize();
        blackhole.consume(cborSerialized);
    }

    @OutputTimeUnit(TimeUnit.SECONDS)
    @Benchmark
    public final void cloudTrail32KBJOLEstimation(Blackhole blackhole) throws JsonProcessingException {
        long jolSize = GraphLayout.parseInstance(cloudTrail32KBEvent).totalSize();
        blackhole.consume(jolSize);
    }

    @Benchmark
    public final void cloudTrail128KBConvertedMapNavigation(Blackhole blackhole) {
        long size = cloudTrail128KBEvent.estimateMemory();
        blackhole.consume(size);
    }

    @Benchmark
    public final void cloudTrail128KBCborSerialization(Blackhole blackhole) throws JsonProcessingException {
        byte[] cborSerialized = cloudTrail128KBEvent.serialize();
        blackhole.consume(cborSerialized);
    }

    @OutputTimeUnit(TimeUnit.SECONDS)
    @Benchmark
    public final void cloudTrail128KBJOLEstimation(Blackhole blackhole) throws JsonProcessingException {
        long jolSize = GraphLayout.parseInstance(cloudTrail128KBEvent).totalSize();
        blackhole.consume(jolSize);
    }

    @Benchmark
    public final void snmp1KBConvertedMapNavigation(Blackhole blackhole) {
        long size = snmp1KBEvent.estimateMemory();
        blackhole.consume(size);
    }

    @Benchmark
    public final void snmp1KBCborSerialization(Blackhole blackhole) throws JsonProcessingException {
        byte[] cborSerialized = snmp1KBEvent.serialize();
        blackhole.consume(cborSerialized);
    }

    @OutputTimeUnit(TimeUnit.SECONDS)
    @Benchmark
    public final void snmp1KBJOLEstimation(Blackhole blackhole) throws JsonProcessingException {
        long jolSize = GraphLayout.parseInstance(snmp1KBEvent).totalSize();
        blackhole.consume(jolSize);
    }

    @Benchmark
    public final void snmp2KBConvertedMapNavigation(Blackhole blackhole) {
        long size = snmp2KBEvent.estimateMemory();
        blackhole.consume(size);
    }

    @Benchmark
    public final void snmp2KBCborSerialization(Blackhole blackhole) throws JsonProcessingException {
        byte[] cborSerialized = snmp2KBEvent.serialize();
        blackhole.consume(cborSerialized);
    }

    @OutputTimeUnit(TimeUnit.SECONDS)
    @Benchmark
    public final void snmp2KBJOLEstimation(Blackhole blackhole) throws JsonProcessingException {
        long jolSize = GraphLayout.parseInstance(snmp2KBEvent).totalSize();
        blackhole.consume(jolSize);
    }

    @Benchmark
    public final void snmp4KBConvertedMapNavigation(Blackhole blackhole) {
        long size = snmp4KBEvent.estimateMemory();
        blackhole.consume(size);
    }

    @Benchmark
    public final void snmp4KBCborSerialization(Blackhole blackhole) throws JsonProcessingException {
        byte[] cborSerialized = snmp4KBEvent.serialize();
        blackhole.consume(cborSerialized);
    }

    @OutputTimeUnit(TimeUnit.SECONDS)
    @Benchmark
    public final void snmp4KBJOLEstimation(Blackhole blackhole) throws JsonProcessingException {
        long jolSize = GraphLayout.parseInstance(snmp4KBEvent).totalSize();
        blackhole.consume(jolSize);
    }

    @Benchmark
    public final void snmp16KBConvertedMapNavigation(Blackhole blackhole) {
        long size = snmp16KBEvent.estimateMemory();
        blackhole.consume(size);
    }

    @Benchmark
    public final void snmp16KBCborSerialization(Blackhole blackhole) throws JsonProcessingException {
        byte[] cborSerialized = snmp16KBEvent.serialize();
        blackhole.consume(cborSerialized);
    }

    @OutputTimeUnit(TimeUnit.SECONDS)
    @Benchmark
    public final void snmp16KBJOLEstimation(Blackhole blackhole) throws JsonProcessingException {
        long jolSize = GraphLayout.parseInstance(snmp16KBEvent).totalSize();
        blackhole.consume(jolSize);
    }

    @Benchmark
    public final void snmp32KBConvertedMapNavigation(Blackhole blackhole) {
        long size = snmp32KBEvent.estimateMemory();
        blackhole.consume(size);
    }

    @Benchmark
    public final void snmp32KBCborSerialization(Blackhole blackhole) throws JsonProcessingException {
        byte[] cborSerialized = snmp32KBEvent.serialize();
        blackhole.consume(cborSerialized);
    }

    @OutputTimeUnit(TimeUnit.SECONDS)
    @Benchmark
    public final void snmp32KBJOLEstimation(Blackhole blackhole) throws JsonProcessingException {
        long jolSize = GraphLayout.parseInstance(snmp32KBEvent).totalSize();
        blackhole.consume(jolSize);
    }

    @Benchmark
    public final void snmp128KBConvertedMapNavigation(Blackhole blackhole) {
        long size = snmp128KBEvent.estimateMemory();
        blackhole.consume(size);
    }

    @Benchmark
    public final void snmp128KBCborSerialization(Blackhole blackhole) throws JsonProcessingException {
        byte[] cborSerialized = snmp128KBEvent.serialize();
        blackhole.consume(cborSerialized);
    }

    @OutputTimeUnit(TimeUnit.SECONDS)
    @Benchmark
    public final void snmp128KBJOLEstimation(Blackhole blackhole) throws JsonProcessingException {
        long jolSize = GraphLayout.parseInstance(snmp128KBEvent).totalSize();
        blackhole.consume(jolSize);
    }
}
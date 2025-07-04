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
* ./gradlew jmh -Pinclude="org.logstash.benchmark.JacksonDeserializeBenchmark.*"
* */

@Warmup(iterations = 3, time = 100, timeUnit = TimeUnit.MILLISECONDS)
@Measurement(iterations = 10, time = 1000, timeUnit = TimeUnit.MILLISECONDS)
@Fork(1)
@BenchmarkMode(Mode.Throughput)
@OutputTimeUnit(TimeUnit.MILLISECONDS)
@State(Scope.Thread)
public class JacksonDeserializeBenchmark {

    private String apache1KBContent;
    private String apache2KBContent;
    private String apache4KBContent;
    private String apache16KBContent;
    private String apache32KBContent;
    private String apache128KBContent;
    private Event apache1KBEvent;

    @Setup(Level.Invocation)
    @SuppressWarnings("unchecked")
    public void setUp() throws IOException {
        apache1KBContent = createTestEvent(Paths.get("../test_events_json/apache_1KB.json"));
        apache1KBEvent = new Event(ObjectMappers.JSON_MAPPER.readValue(apache1KBContent, Map.class));
//        Map<String, Object> jsonEvent = ObjectMappers.JSON_MAPPER.readValue(apache1KBContent, Map.class);
//        apache1KBEvent = new Event(jsonEvent);
//        apache1KBEvent.setField("timestamp", new Timestamp());

        apache2KBContent = createTestEvent(Paths.get("../test_events_json/apache_2KB.json"));
        apache4KBContent = createTestEvent(Paths.get("../test_events_json/apache_4KB.json"));
        apache16KBContent = createTestEvent(Paths.get("../test_events_json/apache_16KB.json"));
        apache32KBContent = createTestEvent(Paths.get("../test_events_json/apache_32KB.json"));
        apache128KBContent = createTestEvent(Paths.get("../test_events_json/apache_128KB.json"));
    }

    private String createTestEvent(Path jsonEventTemplateFile) throws IOException {
        byte[] content = Files.readAllBytes(jsonEventTemplateFile);
        return new String(content, StandardCharsets.UTF_8);
    }

    @Benchmark
    @SuppressWarnings("unchecked")
    public final void apache1KB_JacksonDecode(Blackhole blackhole) throws JsonProcessingException {
        Map<String, Object> jsonEvent = ObjectMappers.JSON_MAPPER.readValue(apache1KBContent, Map.class);
        blackhole.consume(jsonEvent);
    }

    @Benchmark
    public final void apache1KB_measureEvent(Blackhole blackhole) {
        long size = apache1KBEvent.estimateMemory();
        blackhole.consume(size);
    }

    @Benchmark
    @SuppressWarnings("unchecked")
    public final void apache1KBDecodeAndMeasureEvent(Blackhole blackhole) throws JsonProcessingException {
        Map<String, Object> jsonEvent = ObjectMappers.JSON_MAPPER.readValue(apache1KBContent, Map.class);
        Event event = new Event(jsonEvent);
        event.estimateMemory();
        blackhole.consume(event);
    }

    @Benchmark
    @SuppressWarnings("unchecked")
    public final void apache2KB_JacksonDecode(Blackhole blackhole) throws JsonProcessingException {
        Map<String, Object> jsonEvent = ObjectMappers.JSON_MAPPER.readValue(apache2KBContent, Map.class);
        blackhole.consume(jsonEvent);
    }

    @Benchmark
    @SuppressWarnings("unchecked")
    public final void apache4KB_JacksonDecode(Blackhole blackhole) throws JsonProcessingException {
        Map<String, Object> jsonEvent = ObjectMappers.JSON_MAPPER.readValue(apache4KBContent, Map.class);
        blackhole.consume(jsonEvent);
    }

    @Benchmark
    @SuppressWarnings("unchecked")
    public final void apache16KB_JacksonDecode(Blackhole blackhole) throws JsonProcessingException {
        Map<String, Object> jsonEvent = ObjectMappers.JSON_MAPPER.readValue(apache16KBContent, Map.class);
        blackhole.consume(jsonEvent);
    }

    @Benchmark
    @SuppressWarnings("unchecked")
    public final void apache32KB_JacksonDecode(Blackhole blackhole) throws JsonProcessingException {
        Map<String, Object> jsonEvent = ObjectMappers.JSON_MAPPER.readValue(apache32KBContent, Map.class);
        blackhole.consume(jsonEvent);
    }

    @Benchmark
    @SuppressWarnings("unchecked")
    public final void apache128KB_JacksonDecode(Blackhole blackhole) throws JsonProcessingException {
        Map<String, Object> jsonEvent = ObjectMappers.JSON_MAPPER.readValue(apache128KBContent, Map.class);
        blackhole.consume(jsonEvent);
    }

    @Benchmark
    @SuppressWarnings("unchecked")
    public final void apache2KBDecodeAndMeasureEvent(Blackhole blackhole) throws JsonProcessingException {
        Map<String, Object> jsonEvent = ObjectMappers.JSON_MAPPER.readValue(apache2KBContent, Map.class);
        Event event = new Event(jsonEvent);
        event.estimateMemory();
        blackhole.consume(event);
    }

    @Benchmark
    @SuppressWarnings("unchecked")
    public final void apache4KBDecodeAndMeasureEvent(Blackhole blackhole) throws JsonProcessingException {
        Map<String, Object> jsonEvent = ObjectMappers.JSON_MAPPER.readValue(apache4KBContent, Map.class);
        Event event = new Event(jsonEvent);
        event.estimateMemory();
        blackhole.consume(event);
    }

    @Benchmark
    @SuppressWarnings("unchecked")
    public final void apache16KBDecodeAndMeasureEvent(Blackhole blackhole) throws JsonProcessingException {
        Map<String, Object> jsonEvent = ObjectMappers.JSON_MAPPER.readValue(apache16KBContent, Map.class);
        Event event = new Event(jsonEvent);
        event.estimateMemory();
        blackhole.consume(event);
    }

    @Benchmark
    @SuppressWarnings("unchecked")
    public final void apache32KBDecodeAndMeasureEvent(Blackhole blackhole) throws JsonProcessingException {
        Map<String, Object> jsonEvent = ObjectMappers.JSON_MAPPER.readValue(apache32KBContent, Map.class);
        Event event = new Event(jsonEvent);
        event.estimateMemory();
        blackhole.consume(event);
    }

    @Benchmark
    @SuppressWarnings("unchecked")
    public final void apache128KBDecodeAndMeasureEvent(Blackhole blackhole) throws JsonProcessingException {
        Map<String, Object> jsonEvent = ObjectMappers.JSON_MAPPER.readValue(apache128KBContent, Map.class);
        Event event = new Event(jsonEvent);
        event.estimateMemory();
        blackhole.consume(event);
    }
}
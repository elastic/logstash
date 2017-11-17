package org.logstash.stress;

import java.io.IOException;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.List;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.TimeUnit;

import org.logstash.ackedqueue.Batch;
import org.logstash.ackedqueue.SettingsImpl;
import org.logstash.ackedqueue.Queue;
import org.logstash.ackedqueue.Settings;
import org.logstash.ackedqueue.StringElement;
import org.logstash.ackedqueue.io.ByteBufferPageIO;
import org.logstash.ackedqueue.io.CheckpointIOFactory;
import org.logstash.ackedqueue.io.FileCheckpointIO;
import org.logstash.ackedqueue.io.MemoryCheckpointIO;
import org.logstash.ackedqueue.io.MmapPageIO;
import org.logstash.ackedqueue.io.PageIOFactory;

public class Concurrent {
    final static int ELEMENT_COUNT = 2000000;
    final static int BATCH_SIZE = 1000;
    static Settings settings;

    public static Settings memorySettings(int capacity) {
        PageIOFactory pageIOFactory = (pageNum, size, path) -> new ByteBufferPageIO(pageNum, size, path);
        CheckpointIOFactory checkpointIOFactory = (source) -> new MemoryCheckpointIO(source);
        return SettingsImpl.memorySettingsBuilder().capacity(capacity).elementIOFactory(pageIOFactory)
            .checkpointIOFactory(checkpointIOFactory).elementClass(StringElement.class).build();
    }

    public static Settings fileSettings(int capacity) {
        PageIOFactory pageIOFactory = (pageNum, size, path) -> new MmapPageIO(pageNum, size, path);
        CheckpointIOFactory checkpointIOFactory = (source) -> new FileCheckpointIO(source);
        return SettingsImpl.memorySettingsBuilder("/tmp/queue").capacity(capacity)
            .elementIOFactory(pageIOFactory)
            .checkpointIOFactory(checkpointIOFactory).elementClass(StringElement.class).build();
    }

    public static Thread producer(Queue q, List<StringElement> input) {
        return new Thread(() -> {
            try {
                for (StringElement element : input) {
                    q.write(element);
                }
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
        });

    }

    @SuppressWarnings("unchecked")
    public static void oneProducersOneConsumer() throws IOException, InterruptedException {
        List<StringElement> input = new ArrayList<>();
        List<StringElement> output = new ArrayList<>();

        Instant start = Instant.now();

        Queue q = new Queue(settings);
        q.getCheckpointIO().purge();
        q.open();

        System.out.print("stating single producers and single consumers stress test... ");

        for (int i = 0; i < ELEMENT_COUNT; i++) {
            input.add(new StringElement(Integer.toString(i)));
        }

        Thread consumer = new Thread(() -> {
            int consumedCount = 0;

            try {
                while (consumedCount < ELEMENT_COUNT) {
                    Batch b = q.readBatch(BATCH_SIZE, TimeUnit.SECONDS.toMillis(1));
//                    if (b.getElements().size() < BATCH_SIZE) {
//                        System.out.println("read small batch=" + b.getElements().size());
//                    } else {
//                        System.out.println("read batch size=" + b.getElements().size());
//                    }
                    output.addAll((List<StringElement>) b.getElements());
                    b.close();
                    consumedCount += b.getElements().size();
                }
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
        });
        consumer.start();

        Thread producer = producer(q, input);
        producer.start();

        consumer.join();
        q.close();

        Instant end = Instant.now();

        if (! input.equals(output)) {
            System.out.println("ERROR: input and output are not equal");
        } else {
            System.out.println("SUCCESS, result size=" + output.size() + ", elapsed=" + Duration.between(start, end) + ", rate=" + (new Float(ELEMENT_COUNT) / Duration.between(start, end).toMillis()) * 1000);
        }
    }

    @SuppressWarnings("unchecked")
    public static void oneProducersOneMultipleConsumer() throws IOException, InterruptedException {
        final List<StringElement> input = new ArrayList<>();
        final Collection<StringElement> output = new ConcurrentLinkedQueue<>();
        final int CONSUMERS = 5;
        List<Thread> consumers = new ArrayList<>();

        Instant start = Instant.now();

        Queue q = new Queue(settings);
        q.getCheckpointIO().purge();
        q.open();

        System.out.print("stating single producers and multiple consumers stress test... ");

        for (int i = 0; i < ELEMENT_COUNT; i++) {
            input.add(new StringElement(Integer.toString(i)));
        }

        for (int i = 0; i < CONSUMERS; i++) {
            consumers.add(new Thread(() -> {
                try {
                    while (output.size() < ELEMENT_COUNT) {
                        Batch b = q.readBatch(BATCH_SIZE, TimeUnit.SECONDS.toMillis(1));
//                        if (b.getElements().size() < BATCH_SIZE) {
//                            System.out.println("read small batch=" + b.getElements().size());
//                        } else {
//                            System.out.println("read batch size=" + b.getElements().size());
//                        }
                        output.addAll((List<StringElement>) b.getElements());
                        b.close();
                    }
                    // everything is read, close queue here since other consumers might be blocked trying to get next batch
                    q.close();
                } catch (IOException e) {
                    throw new RuntimeException(e);
                }
            }));
        }

        consumers.forEach(Thread::start);

        Thread producer = producer(q, input);
        producer.start();

        // gotta hate exception handling in lambdas
        consumers.forEach(c -> {try{c.join();} catch(InterruptedException e) {throw new RuntimeException(e);}});
        q.close();

        Instant end = Instant.now();

        List<StringElement> result = new ArrayList<>(output);
        result.sort(Comparator.comparing(p -> Integer.valueOf(p.toString())));

        if (! input.equals(result)) {
            System.out.println("ERROR: input and output are not equal");
        } else {
            System.out.println("SUCCESS, result size=" + output.size() + ", elapsed=" + Duration.between(start, end) + ", rate=" + (new Float(ELEMENT_COUNT) / Duration.between(start, end).toMillis()) * 1000);
        }
    }


    public static void main(String[] args) throws IOException, InterruptedException {
        System.out.println(">>> starting in-memory stress test");

        settings = memorySettings(1024 * 1024); // 1MB
        oneProducersOneConsumer();
        oneProducersOneMultipleConsumer();

        System.out.println("\n>>> starting file-based stress test in /tmp/queue");

        settings = fileSettings(1024 * 1024); // 1MB

        oneProducersOneConsumer();
        oneProducersOneMultipleConsumer();
    }

}

package org.logstash.stress;

import org.logstash.ackedqueue.*;
import org.logstash.common.io.*;

import java.io.IOException;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.stream.Collectors;

public class Concurent {
    final static int ELEMENT_COUNT = 2000000;
    final static int BATCH_SIZE = 1000;
    static Settings settings;

    public static Settings memorySettings(int capacity) {
        Settings s = new MemorySettings();
        PageIOFactory pageIOFactory = (pageNum, size, path) -> new ByteBufferPageIO(pageNum, size, path);
        CheckpointIOFactory checkpointIOFactory = (source) -> new MemoryCheckpointIO(source);
        s.setCapacity(capacity);
        s.setElementIOFactory(pageIOFactory);
        s.setCheckpointIOFactory(checkpointIOFactory);
        s.setElementClass(StringElement.class);
        return s;
    }

    public static Settings fileSettings(int capacity) {
        Settings s = new MemorySettings("/tmp/queue");
        PageIOFactory pageIOFactory = (pageNum, size, path) -> new MmapPageIO(pageNum, size, path);
        CheckpointIOFactory checkpointIOFactory = (source) -> new FileCheckpointIO(source);
        s.setCapacity(capacity);
        s.setElementIOFactory(pageIOFactory);
        s.setCheckpointIOFactory(checkpointIOFactory);
        s.setElementClass(StringElement.class);
        return s;
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

    public static void oneProducersOneConsumer() throws IOException, InterruptedException {
        List<StringElement> input = new ArrayList<>();
        List<StringElement> output = new ArrayList<>();

        Instant start = Instant.now();

        Queue q = new Queue(settings);
        q.getCheckpointIO().purge();
        q.open();

        System.out.print("stating single producers and single consumers stress test... ");

        for (int i = 0; i < ELEMENT_COUNT; i++) {
            input.add(new StringElement(new Integer(i).toString()));
        }

        Thread consumer = new Thread(() -> {
            int consumedCount = 0;

            try {
                while (consumedCount < ELEMENT_COUNT) {
                    Batch b = q.readBatch(BATCH_SIZE);
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

    public static void oneProducersOneMultipleConsumer() throws IOException, InterruptedException {
        final List<StringElement> input = new ArrayList<>();
        final Collection<StringElement> output = new ConcurrentLinkedQueue();
        final int CONSUMERS = 5;
        List<Thread> consumers = new ArrayList<>();

        Instant start = Instant.now();

        Queue q = new Queue(settings);
        q.getCheckpointIO().purge();
        q.open();

        System.out.print("stating single producers and multiple consumers stress test... ");

        for (int i = 0; i < ELEMENT_COUNT; i++) {
            input.add(new StringElement(new Integer(i).toString()));
        }

        for (int i = 0; i < CONSUMERS; i++) {
            consumers.add(new Thread(() -> {
                try {
                    while (output.size() < ELEMENT_COUNT) {
                        Batch b = q.readBatch(BATCH_SIZE);
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

        consumers.forEach(c -> c.start());

        Thread producer = producer(q, input);
        producer.start();

        // gotta hate exception handling in lambdas
        consumers.forEach(c -> {try{c.join();} catch(InterruptedException e) {throw new RuntimeException(e);}});

        Instant end = Instant.now();

        List<StringElement> result = output.stream().collect(Collectors.toList());
        Collections.sort(result, (p1, p2) -> Integer.valueOf(p1.toString()).compareTo(Integer.valueOf(p2.toString())));

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

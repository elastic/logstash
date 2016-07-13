package org.logstash.stress;

import org.logstash.ackedqueue.*;
import org.logstash.common.io.ByteBufferPageIO;
import org.logstash.common.io.CheckpointIOFactory;
import org.logstash.common.io.MemoryCheckpointIO;
import org.logstash.common.io.PageIOFactory;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.stream.Collectors;

public class Concurent {
    final static int ELEMENT_COUNT = 1000000;
    final static int PAGE_SIZE = 100 * 1024; // 100k?
    final static int BATCH_SIZE = 1000;

    public static Settings getSettings(int capacity) {
        Settings s = new MemorySettings();
        PageIOFactory pageIOFactory = (size, path) -> new ByteBufferPageIO(size, path);
        CheckpointIOFactory checkpointIOFactory = (source) -> new MemoryCheckpointIO(source);
        s.setCapacity(capacity);
        s.setElementIOFactory(pageIOFactory);
        s.setCheckpointIOFactory(checkpointIOFactory);
        s.setElementDeserialiser(new ElementDeserialiser(StringElement.class));
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

        Queue q = new Queue(getSettings(PAGE_SIZE));
        q.getCheckpointIO().purge();
        q.open();

        System.out.println("stating single producers and single consumers stress test"); // Display the string.

        for (int i = 0; i < ELEMENT_COUNT; i++) {
            input.add(new StringElement("element-" + i, i));
        }

        Thread consumer = new Thread(() -> {
            int consumedCount = 0;

            try {
                while (consumedCount < ELEMENT_COUNT) {
                    Batch b = q.readBatch(BATCH_SIZE);
                    if (b == null) {
                        System.out.println("read batch sleep");
                        Thread.sleep(100);
                    } else {
                        System.out.println("read batch size=" + b.getElements().size());
                        output.addAll((List<StringElement>) b.getElements());
                        b.close();
                        consumedCount += b.getElements().size();
                    }
                }
            } catch (IOException|InterruptedException e) {
                Thread.currentThread().interrupt();
                throw new RuntimeException(e);
            }
        });
        consumer.start();

        Thread producer = producer(q, input);
        producer.start();

        consumer.join();

        if (! input.equals(output)) {
            System.out.println("ERROR: input and output are not equal");
        } else {
            System.out.println("SUCCESS, result size=" + output.size());
        }
    }

    public static void oneProducersOneMultipleConsumer() throws IOException, InterruptedException {
        final List<StringElement> input = new ArrayList<>();
        final Collection<StringElement> output = new ConcurrentLinkedQueue();
        final int CONSUMERS = 5;
        List<Thread> consumers = new ArrayList<>();

        Queue q = new Queue(getSettings(PAGE_SIZE));
        q.getCheckpointIO().purge();
        q.open();

        System.out.println("stating single producers and multiple consumers stress test"); // Display the string.

        for (int i = 0; i < ELEMENT_COUNT; i++) {
            input.add(new StringElement("element-" + i, i));
        }

        for (int i = 0; i < CONSUMERS; i++) {
            consumers.add(new Thread(() -> {
                try {
                    while (output.size() < ELEMENT_COUNT) {
                        Batch b = q.readBatch(BATCH_SIZE);
                        if (b == null) {
                            System.out.println("read batch sleep");
                            Thread.sleep(100);
                        } else {
                            System.out.println("read batch size=" + b.getElements().size());
                            output.addAll((List<StringElement>) b.getElements());
                            b.close();
                        }
                    }
                } catch (IOException | InterruptedException e) {
                    Thread.currentThread().interrupt();
                    throw new RuntimeException(e);
                }
            }));
        }

        consumers.forEach(c -> c.start());

        Thread producer = producer(q, input);
        producer.start();

        consumers.forEach(c -> {try{c.join();} catch(InterruptedException e) {throw new RuntimeException(e);}});


        List<StringElement> result = output.stream().collect(Collectors.toList());
        Collections.sort(result, (p1, p2) -> new Long(p1.getSeqNum()).compareTo(new Long(p2.getSeqNum())));

        if (! input.equals(result)) {
            System.out.println("ERROR: input and output are not equal");
        } else {
            System.out.println("SUCCESS, result size=" + output.size());
        }
    }


    public static void main(String[] args) throws IOException, InterruptedException {
        oneProducersOneConsumer();
        oneProducersOneMultipleConsumer();
    }

}

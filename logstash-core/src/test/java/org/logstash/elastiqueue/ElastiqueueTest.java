package org.logstash.elastiqueue;

import org.apache.http.HttpHost;
import org.junit.Test;
import org.logstash.Event;
import org.logstash.Timestamp;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;
import java.util.concurrent.atomic.LongAdder;

import static org.junit.Assert.*;

public class ElastiqueueTest {
    static String local = "http://localhost:9200";
    static String lan = "http://192.168.1.80:9200";
    public static final HttpHost localhost = HttpHost.create(local);
    public static final AtomicInteger eventsCounter = new AtomicInteger();

    public List<Event> makeEvents(int batchSize) {
        List<Event> events = new ArrayList<>();
        for (int i = 0; i<batchSize; i++) {
            Event e = new Event();
            e.setField("Foo", "bar");
            e.setField("Another T", Timestamp.now());
            e.setField("Sequence", eventsCounter.incrementAndGet());
            events.add(e);
        }
        return events;
    }

    @Test
    public void testSetup() throws IOException, InterruptedException {
        int parallelism = 10;

        Elastiqueue eq = new Elastiqueue(localhost);
        Topic topic = eq.topic("test", parallelism);
        Producer producer = topic.makeProducer("testProducer");

        System.out.println("Start");
        long startedAt = System.nanoTime();
        List<Thread> threads = new ArrayList<>();
        LongAdder eventsWritten = new LongAdder();
        LongAdder batchesWritten = new LongAdder();
        LongAdder eventsRead = new LongAdder();
        LongAdder batchesRead = new LongAdder();

        int numProducers = parallelism;
        int batchesPerProducer = 4000;
        int batchSize = 500;
        int totalBatches = numProducers * batchesPerProducer;
        AtomicLong batchesLeft = new AtomicLong(totalBatches);

        final boolean doProduce = true;

        for (int i =0; i<numProducers; i++) {
            Thread t = new Thread(new Runnable() {
                @Override
                public void run() {
                    long lastSeq = 0;
                    int i = 0;
                    while (doProduce && batchesLeft.getAndDecrement() > 0)  {
                        i++;
                        try {
                            List<Event> events = makeEvents(batchSize);
                            eventsWritten.add(events.size());
                            batchesWritten.increment();
                            lastSeq = producer.write(events.toArray(new Event[events.size()]));
                        } catch (IOException e) {
                            e.printStackTrace();
                        } catch (RuntimeException e) {
                            if (e.getCause() instanceof java.util.concurrent.TimeoutException) {
                                System.out.println("Timeout encountered");
                                continue;
                            } else {
                              e.printStackTrace();
                            }
                        } catch (InterruptedException e) {
                            e.printStackTrace();
                        }
                    }
                    System.out.println("Last Seq " + lastSeq + " TIMES " + i);
                }
            }, "Producer "+i);
            threads.add(t);
            t.start();
        }

        Consumer consumer = topic.makeConsumer("testGroup", "testConsId");
        Thread reporter = new Thread(new Runnable() {
            @Override
            public void run() {
                while (true) {
                    try {
                        Thread.sleep(1000);
                        long endedAt = System.nanoTime();
                                    float runTimeMillis = TimeUnit.MILLISECONDS.convert(endedAt-startedAt, TimeUnit.NANOSECONDS);
                                    float eps = eventsRead.floatValue() / (runTimeMillis / 1000.0f);
                                    System.out.println("\nWRITTEN " + eventsWritten.longValue() + "/" + batchesWritten + " | READ " + eventsRead.longValue() + " | EPS " + eps);
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                }
            }
        }, "Reporter");
        reporter.start();


        for (int i =0; i<parallelism; i++) {
            Thread t = new Thread(new Runnable() {
                @Override
                public void run() {
                    try {
                        int i = 0;
                        Event[] lastResults = new Event[0];
                        while (true) {
                            int timeout = i > 0  ? 100 : 30000;
                            Consumer.EventsWithSeq results = consumer.poll(timeout);

                            if (results != null) {
                                eventsRead.add(results.getEvents().length);
                                batchesRead.increment();
                                //System.out.println("SET OFFSET " + results.getLastSeq());
                                results.setOffset();
                            }

                            if (results != null) {
                                lastResults = results.getEvents();
                                //System.out.println("PollStop " + results.length + " | " + eventsRead.longValue());
                            }
                            if (results != null && results.getEvents().length > 0) {
                                //System.out.println("OVERREAD!" + (eventsRead.longValue() - eventsWritten.longValue()) + " BATCH " + (batchesRead.longValue() - batchesWritten.longValue()));
                            } else {
                                System.out.println("Null Poll, consumer dead.");
                                break;
                            }
                        }
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
            }, "Consumer "+i);
            threads.add(t);
            t.start();
        }

        for (Thread t : threads) {
            t.join();
        }
        long endedAt = System.nanoTime();

        float runTimeMillis = TimeUnit.MILLISECONDS.convert(endedAt-startedAt, TimeUnit.NANOSECONDS);
        float eps = eventsRead.floatValue() / (runTimeMillis / 1000.0f);
        System.out.println("\nWRITTEN " + eventsWritten.longValue() + " | READ " + eventsRead.longValue() + " | EPS " + eps);

        //List<Event> res = consumer.poll();
        //System.out.println(res);
        assertEquals(eventsWritten.longValue(), eventsRead.longValue());
    }

}
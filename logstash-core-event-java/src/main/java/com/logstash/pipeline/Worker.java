package com.logstash.pipeline;

import com.logstash.Event;
import com.logstash.ext.JrubyEventExtLibrary;

import java.io.InputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Set;
import java.util.concurrent.CopyOnWriteArraySet;
import java.util.concurrent.SynchronousQueue;
import java.util.concurrent.TimeUnit;
import java.util.function.IntConsumer;
import java.util.stream.IntStream;

/**
 * Created by andrewvc on 2/20/16.
 */
public class Worker implements Runnable {
    private final int batchDelay;
    private final int batchSize;
    private final SynchronousQueue<Event> queue;
    private final PipelineGraph graph;
    private final String name;
    private volatile Thread thread;

    public static List<Worker> startWorkers(int count, PipelineGraph graph, SynchronousQueue<Event> queue, int batchSize, int batchDelayMs) {
        List<Worker> workers = new ArrayList(count);
        for (int i=0; i < count; i++ ) {
            String name = String.format("[main]>worker%d", i);
            Worker worker = new Worker(name, graph, queue, batchSize, batchDelayMs);
            worker.start();
            workers.add(worker);
        }
        return workers;
    }


    Worker(String name, PipelineGraph graph, SynchronousQueue<Event> queue, int batchSize, int batchDelayMs) {
        this.name = name;
        this.graph = graph;
        this.queue = queue;
        this.batchSize = batchSize;
        this.batchDelay = batchDelayMs;
    }

    public Thread start() {
        Thread thread = new Thread(this);
        thread.setName(this.name);
        this.thread = thread;
        thread.start();
        return thread;
    }

    @Override
    public void run() {
        boolean isShutdown = false;
        while (!isShutdown) {
            Batch batch = takeBatch();
            batch = processBatch(batch);
            if (batch.isFlush()) graph.flush(batch.isShutdown());

            isShutdown = batch.isShutdown(); // Stop the loop
        }
    }

    public Batch takeBatch() {
        boolean flush = false;
        boolean shutdown = false;
        int batchSequence = 0;

        final List<Event> events = new ArrayList<>(batchSize);

        for (int i = 0; i < batchSize; i++) {
            Event event;

            try {
                if (i == 0) {
                    event = queue.take();
                } else {
                    event = queue.poll(batchDelay, TimeUnit.MILLISECONDS);
                }
            } catch (InterruptedException e) {
                break;
            }

            if (event == Constants.flushEvent) {
                flush = true;
            } else if (event == Constants.shutdownEvent) {
                shutdown = true;
            } else if (event != null) {
                batchSequence++;
                event.setBatchSequence(batchSequence);
                events.add(event);
            }
        }

        return new Batch(events, flush, shutdown);
    }

    public Batch processBatch(Batch batch) {
        graph.processWorker(batch);
        return batch;
    }

    public Thread getThread() {
        return thread;
    }

}

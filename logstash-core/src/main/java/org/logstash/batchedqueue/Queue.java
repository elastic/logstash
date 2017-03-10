package org.logstash.batchedqueue;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

public class Queue<E> {

    // thread safety
    final Lock lock = new ReentrantLock();
    final Condition notFull  = lock.newCondition();
    final Condition notEmpty = lock.newCondition();

    private final int WORKERS = 4;

    final int limit;
    private List[] batches;
    private int write_batch;
    private int read_batch;

    public Queue(int limit) {
        this.limit = limit;
        this.batches = new  List[WORKERS];
        this.write_batch = 0;
        this.read_batch = 0;
        for (int i = 0; i < WORKERS; i++) {
            this.batches[i] = new ArrayList<E>();
        }
    }

    private int next_write_batch() {
        return (this.write_batch + 1) % WORKERS;
    }

    private void inc_write_batch() {
        this.write_batch = (this.write_batch + 1) % WORKERS;
    }

    private void inc_read_batch() {
        this.read_batch = (this.read_batch + 1) % WORKERS;
    }


    public void write(E element) {
        lock.lock();
        try {

            // empty queue shortcut
            if (_isEmpty()) {
                this.batches[this.write_batch].add(element);
                notEmpty.signal();
                return;
            }

            while (isFull()) {
                try {
                    notFull.await();
                } catch (InterruptedException e) {
                    // the thread interrupt() has been called while in the await() blocking call.
                    // at this point the interrupted flag is reset and Thread.interrupted() will return false
                    // to any upstream calls on it. for now our choice is to return normally and set back
                    // the Thread.interrupted() flag so it can be checked upstream.

                    // set back the interrupted flag
                    Thread.currentThread().interrupt();

                    return;
                }
            }

            if (this.batches[this.write_batch].size() >= this.limit) {
                inc_write_batch();
            }
            this.batches[this.write_batch].add(element);
        } finally {
            lock.unlock();
        }
    }

    private boolean isFull() {
        return next_write_batch() == read_batch && this.batches[this.write_batch].size() >= this.limit;
    }

    private boolean _isEmpty() {
        return this.read_batch == this.write_batch && this.batches[this.read_batch].isEmpty();
    }

    public boolean isEmpty() {
        lock.lock();
        try {
            return _isEmpty();
        } finally {
            lock.unlock();
        }
    }

    public List<E> nonBlockReadBatch() {
        lock.lock();
        try {
            // full queue shortcut
            if (isFull()) {
                List<E> batch = swap();
                notFull.signalAll();
                return batch;
            }

            if (_isEmpty()) { return null; }

            return swap();
        } finally {
            lock.unlock();
        }
    }

    public List<E> readBatch() {
        return null;
    }

    public List<E> readBatch(long timeout) {
        lock.lock();
        try {
            while (_isEmpty()) {
                //System.out.println("*** isEmpty");
                try {
                    boolean timedout = !notEmpty.await(timeout, TimeUnit.MILLISECONDS); // await return false when reaching timeout
                    if (timedout) { break; }
                } catch (InterruptedException e) {
                    // the thread interrupt() has been called while in the await() blocking call.
                    // at this point the interrupted flag is reset and Thread.interrupted() will return false
                    // to any upstream calls on it. for now our choice is to simply return null and set back
                    // the Thread.interrupted() flag so it can be checked upstream.

                    // set back the interrupted flag
                    Thread.currentThread().interrupt();

                    return null;
                }
            }

            if (_isEmpty()) { return null; }

            if (isFull()) {
                //System.out.println("*** isFull");
                List<E> batch = swap();
                notFull.signalAll();
                return batch;
            }

            return swap();
        } finally {
            lock.unlock();
        }
    }

    public void close() {
        // nothing
    }


    private List<E> swap() {
        List<E> batch = this.batches[this.read_batch];
        this.batches[this.read_batch] = new ArrayList<>();
        if (this.read_batch != this.write_batch) {
            inc_read_batch();
        }
        return batch;
    }

}
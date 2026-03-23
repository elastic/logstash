package org.logstash.execution;

import java.util.concurrent.atomic.AtomicBoolean;

public class PipelineControlState {
    private final AtomicBoolean ready = new AtomicBoolean(false);
    private final AtomicBoolean running = new AtomicBoolean(false);
    private final AtomicBoolean flushing =  new AtomicBoolean(false);
    private final AtomicBoolean flushRequested = new AtomicBoolean(false);
    private final AtomicBoolean shutdownRequested = new AtomicBoolean(false);
    private final AtomicBoolean crashDetected = new AtomicBoolean(false);
    private final AtomicBoolean outputsRegistered = new AtomicBoolean(false);
    private final AtomicBoolean finishedExecution = new AtomicBoolean(false);
    private final AtomicBoolean finishedRun = new AtomicBoolean(false);

    public boolean isReady() {
        return ready.get();
    }

    public void setReady(boolean ready) {
        this.ready.set(ready);
    }

    public boolean isRunning() {
        return running.get();
    }

    public void setRunning(boolean running) {
        this.running.set(running);
    }

    public boolean isFlushing() {
        return flushing.get();
    }

    public void setFlushing(boolean flushing) {
        this.flushing.set(flushing);
    }

    public boolean consumeFlushRequested() {
        return this.flushRequested.compareAndSet(true, false);
    }

    public boolean isShutdownRequested() {
        return shutdownRequested.get();
    }

    public boolean isCrashDetected() {
        return crashDetected.get();
    }

    public void setCrashDetected(final boolean crashDetected) {
        this.crashDetected.set(crashDetected);
    }

    public void setShutdownRequested(boolean shutdownRequested) {
        this.shutdownRequested.set(shutdownRequested);
    }

    public boolean isOutputsRegistered() {
        return outputsRegistered.get();
    }

    public boolean isFinishedExecution() {
        return finishedExecution.get();
    }

    public void setFinishedExecution(boolean finishedExecution) {
        this.finishedExecution.set(finishedExecution);
    }

    public boolean isFinishedRun() {
        return finishedRun.get();
    }

    public void setFinishedRun(boolean finishedRun) {
        this.finishedRun.set(finishedRun);
    }

    public boolean claimOutputsRegistration() {
        return this.outputsRegistered.compareAndSet(false, false);
    }

    public PeriodicFlush createPeriodicFlush() {
        return new PeriodicFlush(this.flushRequested, this.flushing);
    }
}

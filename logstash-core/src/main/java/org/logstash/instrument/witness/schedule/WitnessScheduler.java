package org.logstash.instrument.witness.schedule;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

/**
 * Schedules {@link ScheduledWitness} to refresh themselves on an interval.
 */
public class WitnessScheduler {

    private final ScheduledWitness witness;
    private final ScheduledExecutorService executorService;
    private static final Logger LOGGER = LogManager.getLogger(WitnessScheduler.class);

    /**
     * Constructor
     *
     * @param witness the {@link ScheduledWitness} to schedule
     */
    public WitnessScheduler(ScheduledWitness witness) {
        this.witness = witness;

        this.executorService = Executors.newScheduledThreadPool(1, ((Runnable r) -> {
            Thread t = new Thread(r);
            //Allow this thread to simply die when the JVM dies
            t.setDaemon(true);
            //Set the name
            t.setName(witness.threadName());
            return t;
        }));
    }

    /**
     * Schedules the witness to refresh on provided schedule. Note - this implementation does not allow refreshes faster then every 1 second.
     */
    public void schedule() {
        executorService.scheduleAtFixedRate(new RefreshRunnable(), 0, witness.every().getSeconds(), TimeUnit.SECONDS);
    }

    /**
     * Shuts down the underlying executor service. Since these are daemon threads, this is not absolutely necessary.
     */
    public void shutdown(){
        executorService.shutdown();
        try {
            if(!executorService.awaitTermination(5, TimeUnit.SECONDS)){
                executorService.shutdownNow();
            }
        } catch (InterruptedException e) {
            throw new IllegalStateException("Witness should be scheduled from the main thread, and the main thread does not expect to be interrupted", e);
        }
    }

    /**
     * Runnable that will won't cancel the scheduled tasks on refresh if an exception is thrown, and throttles the log message.
     */
    class RefreshRunnable implements Runnable {

       long lastLogged = 0;

        @Override
        public void run() {
            try {
                witness.refresh();
            } catch (Exception e) {
                long now = System.currentTimeMillis();
                //throttle to only log the warning if it hasn't been logged in the past 120 seconds, this will ensure at least 1 log message, and logging for intermittent issues,
                // but keep from flooding the log file on a repeating error on every schedule
                if (lastLogged == 0 || now - lastLogged > 120_000) {
                    LOGGER.warn("Can not fully refresh the metrics for the " + witness.getClass().getSimpleName(), e);
                }
                lastLogged = now;
            }
        }
    }
}

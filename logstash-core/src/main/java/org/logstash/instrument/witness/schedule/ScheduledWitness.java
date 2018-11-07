package org.logstash.instrument.witness.schedule;

import java.time.Duration;

/**
 * A witness that is self-populating on a given schedule.
 */
public interface ScheduledWitness {

    /**
     * The duration between updates for this witness
     *
     * @return the {@link Duration} between scheduled updates. For example {@link Duration#ofMinutes(long)} with a value of 5 would schedule this implementation to
     * self-populate every 5 minute. Defaults to every 60 seconds. - Note, implementations may not allow schedules faster then every 1 second.
     */
    default Duration every() {
        //note - the system property is an only an escape hatch if this proves to cause performance issues. Do not document this system property, it is not part of the contract.
        return Duration.ofSeconds(Long.parseLong(System.getProperty("witness.scheduled.duration.in.seconds", "10")));
    }

    /**
     * Get the name to set for the thread on which this is scheduled. This is useful for debugging purposes. Defaults to the class name + -thread.
     *
     * @return The name for the scheduled thread.
     */
    default String threadName() {
        return getClass().getSimpleName() + "-thread";
    }

    /**
     * Updates the underlying metrics on the given schedule.
     */
    void refresh();
}

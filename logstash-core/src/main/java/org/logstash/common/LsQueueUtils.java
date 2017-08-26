package org.logstash.common;

import java.util.Collection;
import java.util.HashSet;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.TimeUnit;
import org.logstash.ext.JrubyEventExtLibrary;

/**
 * Utilities around {@link BlockingQueue}.
 */
public final class LsQueueUtils {

    private LsQueueUtils() {
        //Utility Class
    }

    /**
     * <p>Drains {@link JrubyEventExtLibrary.RubyEvent} from {@link BlockingQueue} with a timeout.</p>
     * <p>The timeout will be reset as soon as a single {@link JrubyEventExtLibrary.RubyEvent} was
     * drained from the {@link BlockingQueue}. Draining {@link JrubyEventExtLibrary.RubyEvent}
     * stops as soon as either the required number of {@link JrubyEventExtLibrary.RubyEvent}s
     * were pulled from the queue or the timeout value has gone by without an event drained.</p>
     * @param queue Blocking Queue to drain {@link JrubyEventExtLibrary.RubyEvent}s
     * from
     * @param count Number of {@link JrubyEventExtLibrary.RubyEvent}s to drain from
     * {@link BlockingQueue}
     * @param nanos Timeout in Nanoseconds
     * @return Collection of {@link JrubyEventExtLibrary.RubyEvent} drained from
     * {@link BlockingQueue}
     * @throws InterruptedException On Interrupt during {@link BlockingQueue#poll()} or
     * {@link BlockingQueue#drainTo(Collection)}
     */
    public static Collection<JrubyEventExtLibrary.RubyEvent> drain(
        final BlockingQueue<JrubyEventExtLibrary.RubyEvent> queue, final int count, final long nanos
    ) throws InterruptedException {
        int left = count;
        final Collection<JrubyEventExtLibrary.RubyEvent> collection =
            new HashSet<>(4 * count / 3 + 1);
        while (left > 0) {
            final int drained = drain(queue, collection, left, nanos);
            if (drained == 0) {
                break;
            }
            left -= drained;
        }
        return collection;
    }

    /**
     * Tries to drain a given number of {@link JrubyEventExtLibrary.RubyEvent} from
     * {@link BlockingQueue} with a timeout.
     * @param queue Blocking Queue to drain {@link JrubyEventExtLibrary.RubyEvent}s
     * from
     * @param count Number of {@link JrubyEventExtLibrary.RubyEvent}s to drain from
     * {@link BlockingQueue}
     * @param nanos Timeout in Nanoseconds
     * @return Collection of {@link JrubyEventExtLibrary.RubyEvent} drained from
     * {@link BlockingQueue}
     * @throws InterruptedException On Interrupt during {@link BlockingQueue#poll()} or
     * {@link BlockingQueue#drainTo(Collection)}
     */
    private static int drain(final BlockingQueue<JrubyEventExtLibrary.RubyEvent> queue,
        final Collection<JrubyEventExtLibrary.RubyEvent> collection, final int count,
        final long nanos) throws InterruptedException {
        final long deadline = System.nanoTime() + nanos;
        int added = 0;
        while (added < count) {
            added += queue.drainTo(collection, count - added);
            if (added < count) {
                final JrubyEventExtLibrary.RubyEvent event =
                    queue.poll(deadline - System.nanoTime(), TimeUnit.NANOSECONDS);
                if (event == null) {
                    break;
                }
                collection.add(event);
                added++;
            }
        }
        return added;
    }

}

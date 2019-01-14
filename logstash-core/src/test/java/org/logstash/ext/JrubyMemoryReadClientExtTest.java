package org.logstash.ext;

import java.util.Map;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;
import org.jruby.RubyHash;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.junit.Test;
import org.logstash.RubyUtil;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;

/**
 * Tests for {@link JrubyMemoryReadClientExt}.
 */
public final class JrubyMemoryReadClientExtTest {

    @Test
    public void testInflightBatchesTracking() throws InterruptedException {
        final BlockingQueue<JrubyEventExtLibrary.RubyEvent> queue =
            new ArrayBlockingQueue<>(10);
        final JrubyMemoryReadClientExt client =
            JrubyMemoryReadClientExt.create(queue, 5, 50);
        final ThreadContext context = RubyUtil.RUBY.getCurrentContext();
        final IRubyObject batch = client.readBatch(context);
        final RubyHash inflight = (RubyHash) client.rubyGetInflightBatches(context);
        assertThat(inflight.size(), is(1));
        assertThat(inflight.get(Thread.currentThread().getId()), is(batch));
        client.closeBatch(context, batch);
        assertThat(((Map<?, ?>) client.rubyGetInflightBatches(context)).size(), is(0));
    }
}

package org.logstash.config.ir.compiler;

import java.util.Collection;
import org.jruby.RubyHash;
import org.jruby.RubyInteger;
import org.jruby.RubyString;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.ext.JrubyEventExtLibrary;

/**
 * This class holds interfaces implemented by Ruby concrete classes.
 */
public final class RubyIntegration {

    private RubyIntegration() {
        //Utility Class.
    }

    /**
     * A Ruby Plugin.
     */
    public interface Plugin {
        void register();
    }

    /**
     * A Ruby Filter. Currently, this interface is implemented only by the Ruby class
     * {@code FilterDelegator}.
     */
    public interface Filter extends RubyIntegration.Plugin {

        /**
         * Same as {@code FilterDelegator}'s {@code multi_filter}.
         * @param events Events to Filter
         * @return Filtered {@link JrubyEventExtLibrary.RubyEvent}
         */
        Collection<JrubyEventExtLibrary.RubyEvent> multiFilter(
            Collection<JrubyEventExtLibrary.RubyEvent> events
        );

        Collection<JrubyEventExtLibrary.RubyEvent> flush(RubyHash options);

        /**
         * Checks if this filter has a flush method.
         * @return True iff this filter has a flush method
         */
        boolean hasFlush();

        /**
         * Checks if this filter does periodic flushing.
         * @return True iff this filter uses periodic flushing
         */
        boolean periodicFlush();
    }

    /**
     * A Ruby Output. Currently, this interface is implemented only by the Ruby class
     * {@code OutputDelegator}.
     */
    public interface Output extends RubyIntegration.Plugin {
        void multiReceive(Collection<JrubyEventExtLibrary.RubyEvent> events);
    }

    /**
     * The Main Ruby Pipeline Class. Currently, this interface is implemented only by the Ruby class
     * {@code BasePipeline}.
     */
    public interface Pipeline {

        IRubyObject buildInput(RubyString name, RubyInteger line, RubyInteger column,
            IRubyObject args);

        RubyIntegration.Output buildOutput(RubyString name, RubyInteger line, RubyInteger column,
            IRubyObject args);

        RubyIntegration.Filter buildFilter(RubyString name, RubyInteger line, RubyInteger column,
            IRubyObject args);

        RubyIntegration.Filter buildCodec(RubyString name, IRubyObject args);
    }

    /**
     * A Ruby {@code ReadBatch} implemented by {@code WrappedSynchronousQueue::ReadClient::ReadBatch}
     * and {@code WrappedAckedQueue::ReadClient::ReadBatch}.
     */
    public interface Batch {

        /**
         * Retrieves all {@link JrubyEventExtLibrary.RubyEvent} from the batch that are not
         * cancelled.
         * @return Collection of all {@link JrubyEventExtLibrary.RubyEvent} in the batch that
         * are not cancelled
         */
        Collection<JrubyEventExtLibrary.RubyEvent> collect();
        
        void merge(JrubyEventExtLibrary.RubyEvent event);
    }
}

/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


package org.logstash.config.ir.compiler;

import java.util.Collection;
import org.jruby.RubyArray;
import org.logstash.ext.JrubyEventExtLibrary;

/**
 * <p>A data structure backed by a {@link RubyArray} that represents one step of execution flow of a
 * batch is lazily filled with {@link org.logstash.ext.JrubyEventExtLibrary.RubyEvent} computed from its dependent
 * {@link Dataset}.</p>
 * <p>Each {@link Dataset} either represents a filter, output or one branch of an {@code if}
 * statement in a Logstash configuration file.</p>
 * <p>Note: It does seem more natural to use the {@code clear} invocation to set the next
 * batch of input trueData. For now this is intentionally not implemented since we want to clear
 * the trueData stored in the Dataset tree as early as possible and before the output operations
 * finish. Once the whole execution tree including the output operation is implemented in
 * Java, this API can be adjusted as such.</p>
 */
public interface Dataset {

    /**
     * Dataset that does not modify the input events.
     */
    Dataset IDENTITY = new Dataset() {
        @SuppressWarnings("unchecked")
        @Override
        public Collection<JrubyEventExtLibrary.RubyEvent> compute(final @SuppressWarnings("rawtypes") RubyArray batch,
                                                                  final boolean flush, final boolean shutdown) {
            return batch;
        }

        @Override
        public void clear() {
        }
    };

    /**
     * Compute the actual contents of the backing {@link RubyArray} and cache them.
     * Repeated invocations will be effectively free.
     * @param batch Input {@link org.logstash.ext.JrubyEventExtLibrary.RubyEvent} received at the root
     * of the execution
     * @param flush True if flushing flushable nodes while traversing the execution
     * @param shutdown True if this is the last call to this instance's compute method because
     * the pipeline it belongs to is shut down
     * @return Computed {@link RubyArray} of {@link org.logstash.ext.JrubyEventExtLibrary.RubyEvent}
     */
    Collection<JrubyEventExtLibrary.RubyEvent> compute(@SuppressWarnings({"rawtypes"}) RubyArray batch,
        boolean flush, boolean shutdown);

    /**
     * Removes all data from the instance and all of its parents, making the instance ready for
     * use with a new set of input data.
     */
    void clear();
}

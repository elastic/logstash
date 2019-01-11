package org.logstash.plugin;

import org.logstash.Event;
import org.logstash.FieldReference;
import org.logstash.Javafier;
import org.logstash.PathCache;

import java.util.Map;
import java.util.Optional;
import java.util.function.Consumer;

/**
 * A builder for the Mutate processor which builds a chain of Consumers.
 * <p>
 * This differs from the Ruby implementation by using build-time knowledge to build a consumer that
 * executes exactly the required steps and nothing more.
 * <p>
 * In Ruby, we always check if @convert is set, for example, and this model (chaining Consumer.andThen),
 * we can build a Consumer that doesn't waste any energy on things never configured by the user.
 * <p>
 * XXX: Would this be similarly efficient as a Processor that lazily built itself?
 * <p>
 * Something like:
 * void process(Event event) {
 * if (this.consumer == null) { build(); }
 * this.consumer.accept(event);
 * }
 */
class MutateProcessorBuilder {
    private Consumer<Event> consumer;

    MutateProcessorBuilder withConvert(Map<String, Object> map) {
        for (Map.Entry<String, Object> entry : map.entrySet()) {
            FieldReference ref = PathCache.cache(entry.getKey());
            Optional<Conversion> result = Conversion.lookup((String) entry.getValue());
            if (!result.isPresent()) {
                throw new IllegalArgumentException("Invalid conversion '" + entry.getValue() + "'. Must be one of: " + Conversion.names());
            }

            Conversion conversion = result.get();

            append((Event event) -> {
                if (event.includes(ref)) {
                    Object value = event.getUnconvertedField(ref);
                    if (value != null) {
                        event.setField(ref, conversion.convert(Javafier.deep(value)));
                    }
                }
            });
        }

        return this;
    }

    private void append(Consumer<Event> consumer) {
        if (this.consumer == null) {
            this.consumer = consumer;
        } else {
            //System.out.println("Appending consumer: " + consumer);
            this.consumer = this.consumer.andThen(consumer);
        }
    }


    Consumer<Event> build() {
        return consumer;
    }

}

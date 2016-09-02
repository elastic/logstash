package org.logstash.config.compiler.compiled;

import org.logstash.Event;

import java.util.Collection;
import java.util.Collections;
import java.util.List;

/**
 * Created by andrewvc on 9/22/16.
 */
public interface ICompiledExpression {
    List<Boolean> execute(Collection<Event> events);

    default Boolean execute(Event event) {
        return execute(Collections.singletonList(event)).get(0);
    }
}

package co.elastic.logstash.api;

import org.logstash.Timestamp;

import java.io.IOException;
import java.util.Map;

/**
 * Event interface for Java plugins. Java plugins should be not rely on the implementation details of any
 * concrete implementaions of the Event interface.
 */
public interface Event {
    Map<String, Object> getData();

    Map<String, Object> getMetadata();

    void cancel();

    void uncancel();

    boolean isCancelled();

    Timestamp getTimestamp() throws IOException;

    void setTimestamp(Timestamp t);

    Object getField(String reference);

    Object getUnconvertedField(String reference);

    void setField(String reference, Object value);

    boolean includes(String field);

    Map<String, Object> toMap();

    Event overwrite(Event e);

    Event append(Event e);

    Object remove(String path);

    String sprintf(String s) throws IOException;

    Event clone();

    String toString();

    void tag(String tag);
}

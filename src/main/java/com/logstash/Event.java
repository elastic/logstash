package com.logstash;

import java.io.IOException;
import java.util.Map;

public interface Event extends Cloneable {

    String toString();

    void cancel();

    void uncancel();

    boolean isCancelled();

    Map<String, Object> getData();

    void setData(Map<String, Object> data);

    Accessors getAccessors();

    void setAccessors(Accessors accessors);

    Timestamp getTimestamp();

    void setTimestamp(Timestamp t);

    Object getField(String reference);

    void setField(String reference, Object value);

    boolean includes(String reference);

    Object remove(String reference);

    String toJson() throws IOException;

    // TODO: see if we need that here or just as a to_hash in the JRuby layer
    Map toMap();

    Event overwrite(Event e);

    Event append(Event e);

    String sprintf(String s) throws IOException;

    void tag(String tag);

    Event clone() throws CloneNotSupportedException;
}

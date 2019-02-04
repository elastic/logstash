package co.elastic.logstash.api;

import java.io.Serializable;
import java.util.Map;

public interface EventFactory {

    /**
     * @return New and empty event.
     */
    Event newEvent();

    /**
     * @param data Map from which the new event should copy its data.
     * @return     New event copied from the supplied map data.
     */
    Event newEvent(final Map<? extends Serializable, Object> data);
}

package co.elastic.logstash.api;

/**
 * Mechanism by which filters indicate which events "match". The common actions for filters such as {@code add_field}
 * and {@code add_tag} are applied only to events that are designated as "matching". Some filters such as the
 * <a href="https://www.elastic.co/guide/en/logstash/current/plugins-filters-grok.html">grok filter</a> have a clear
 * definition for what constitutes a matching event and will notify the listener only for matching events. Other
 * filters such as the <a href="https://www.elastic.co/guide/en/logstash/current/plugins-filters-uuid.html">UUID
 * filter</a> have no specific match criteria and should notify the listener for every event filtered.
 */
public interface FilterMatchListener {

    /**
     * Notify the filter match listener that the specified event "matches" the filter criteria.
     * @param e Event that matches the filter criteria.
     */
    void filterMatched(Event e);
}

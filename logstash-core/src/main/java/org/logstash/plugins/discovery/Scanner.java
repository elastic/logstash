package org.logstash.plugins.discovery;

import com.google.common.base.Predicate;
import com.google.common.collect.Multimap;

/**
 *
 */
public interface Scanner {

    void setConfiguration(Configuration configuration);

    Multimap<String, String> getStore();

    void setStore(Multimap<String, String> store);

    Scanner filterResultsBy(Predicate<String> filter);

    boolean acceptsInput(String file);

    Object scan(Vfs.File file, Object classObject);

    boolean acceptResult(String fqn);
}

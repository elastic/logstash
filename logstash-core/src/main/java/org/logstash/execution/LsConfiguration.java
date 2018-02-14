package org.logstash.execution;

import java.util.Collection;
import java.util.Properties;

/**
 * LS Configuration example. Should be implemented like Spark config or Hadoop job config classes.
 */
public final class LsConfiguration {

    public String getString(final String key) {
        return "";
    }

    public int getInt(final String key) {
        return 0;
    }

    public Collection<Properties> allProperties() {
        // TODO: Return list of all defined properties
        return null;
    }

    //TODO: all types we care about

    public static final class Property {

        public Property(final Class<?> type, final String name, final boolean deprecated) {
            // TODO: So on and so forth add
        }

    }
}

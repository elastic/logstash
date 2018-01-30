package org.logstash.execution;

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

    //TODO: all types we care about
}

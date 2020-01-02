package org.logstash.log;

import java.util.HashMap;
import java.util.Map;

/**
 * Utility class to save & restore a specified list of System properties
 * */
class SystemPropsSnapshotHelper {

    private final Map<String, String> systemPropertiesDump = new HashMap<>();

    public void takeSnapshot(String... propertyNames) {
        for (String propertyName : propertyNames) {
            dumpSystemProperty(propertyName);
        }
    }

    public void restoreSnapshot(String... propertyNames) {
        for (String propertyName : propertyNames) {
            dumpSystemProperty(propertyName);
        }
    }

    private void dumpSystemProperty(String propertyName) {
        systemPropertiesDump.put(propertyName, System.getProperty(propertyName));
    }

    private void restoreSystemProperty(String propertyName) {
        if (systemPropertiesDump.get(propertyName) == null) {
            System.clearProperty(propertyName);
        } else {
            System.setProperty(propertyName, systemPropertiesDump.get(propertyName));
        }
    }
}

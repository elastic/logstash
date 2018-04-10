package org.logstash.pluginmanager;

import org.junit.Before;
import org.junit.Test;

import java.util.Collection;
import java.util.Collections;

public class PluginManagerTest {
    PluginManager manager;

    @Before
    public void initialize() {
       manager = new PluginManager();
    }

    String validShortAddress = "com.example:logstash-filter-animal";
    Collection<String> validShortAddresses = Collections.singleton(validShortAddress);

    @Test
    public void workflow() {
       manager.installLatest(validShortAddresses);

    }

}
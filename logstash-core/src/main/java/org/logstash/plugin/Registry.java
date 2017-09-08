package org.logstash.plugin;

import java.util.ArrayList;
import java.util.List;

public class Registry {
    private List<Plugin> plugins = new ArrayList<>();

    public Registry() {
    }

    public void register(Plugin plugin) {
        plugins.add(plugin);
    }
}

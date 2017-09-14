package org.logstash.plugin;

public interface Field {
    Field setDeprecated(String details);

    Field setObsolete(String details);
}

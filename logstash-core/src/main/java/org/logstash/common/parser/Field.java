package org.logstash.common.parser;

public interface Field {
    Field setDeprecated(String details);

    Field setObsolete(String details);
}

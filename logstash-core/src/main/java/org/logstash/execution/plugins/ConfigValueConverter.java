package org.logstash.execution.plugins;

public interface ConfigValueConverter<T> {
    T convertValue(String rawValue);
}

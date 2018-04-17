package org.logstash.execution.plugins;

public class StringConfigValueConverter implements ConfigValueConverter<String> {
    @Override
    public String convertValue(String rawValue) {
        return rawValue;
    }
}

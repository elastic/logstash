package org.logstash.common;

public interface EnvironmentVariableProvider {

    String get(String key);

    static EnvironmentVariableProvider defaultProvider() {
        return System::getenv;
    }
}

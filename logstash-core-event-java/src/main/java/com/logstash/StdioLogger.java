package com.logstash;

public class StdioLogger implements Logger {

    // TODO: (colin) complete implementation beyond warn when needed

    public void warn(String message) {
        System.out.println(message);
    }
}

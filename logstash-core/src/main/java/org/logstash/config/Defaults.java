package org.logstash.config;

public final class Defaults {

    public static String input() {
        return "input { stdin { type => stdin } }";
    }

    public static String output() {
        return "output { stdout { codec => rubydebug } }";
    }

    public static int cpuCores() {
        return Runtime.getRuntime().availableProcessors();
    }
}

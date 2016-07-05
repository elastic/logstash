package org.logstash.log;

import org.apache.logging.log4j.LogManager;

import org.apache.logging.log4j.Logger;

import java.util.Collections;

public class Main {
    private static final Logger logger = LogManager.getLogger(Main.class);

    public static void main(String[] args) {
        ExampleEvent event = new ExampleEvent();
        event.setField("first", Collections.singletonMap("wow", 21));
        logger.info("hello, I am a simple structured message");
        logger.info("hello, I am a very structured message", "event", event, "what", "hello");
    }
}

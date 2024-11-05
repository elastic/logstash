package org.logstash.log;

import org.apache.logging.log4j.core.*;
import org.apache.logging.log4j.test.appender.ListAppender;
import org.junit.rules.ExternalResource;

import java.util.List;

public class LoggingSpyResource extends ExternalResource {

    private static final String APPENDER_NAME = "spyAppender";

    private final Logger loggerToSpyOn;
    private final ListAppender appender = new ListAppender(APPENDER_NAME);

    public LoggingSpyResource(final org.apache.logging.log4j.Logger loggerToSpyOn) {
        this.loggerToSpyOn = (Logger) loggerToSpyOn;
    }

    @Override
    protected void before() throws Throwable {
        appender.start();
        loggerToSpyOn.addAppender(appender);
    }

    @Override
    protected void after() {
        loggerToSpyOn.removeAppender(appender);
    }

    public List<LogEvent> getLogEvents() {
        return List.copyOf(appender.getEvents());
    }
}

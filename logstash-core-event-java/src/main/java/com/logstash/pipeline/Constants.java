package com.logstash.pipeline;

import com.logstash.Event;

/**
 * Created by andrewvc on 2/20/16.
 */
public class Constants {
    public final static Event shutdownEvent = new Event();
    public final static Event flushEvent = new Event();
}

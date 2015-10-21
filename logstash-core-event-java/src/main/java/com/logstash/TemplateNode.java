package com.logstash;

import org.codehaus.jackson.JsonGenerationException;

import java.io.IOException;

/**
 * Created by ph on 15-05-22.
 */
public interface TemplateNode {
    String evaluate(Event event) throws IOException;
}

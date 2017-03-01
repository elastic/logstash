package org.logstash;

import java.io.IOException;

/**
 * Created by ph on 15-05-22.
 */
public interface TemplateNode {
    String evaluate(Event event) throws IOException;
}

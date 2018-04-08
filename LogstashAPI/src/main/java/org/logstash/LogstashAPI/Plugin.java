package org.logstash.LogstashAPI;

import java.lang.annotation.*;

@Documented
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
public @interface Plugin {
    /**
     * The name of the plugin
     */
    String value();
}
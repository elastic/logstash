package org.logstash.plugins.api;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Logstash plugin annotation for finding plugins on the classpath and setting their name as used
 * in the configuration syntax.
 */
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
public @interface LogstashPlugin {
    String name();
}

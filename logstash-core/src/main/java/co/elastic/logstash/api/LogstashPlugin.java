package co.elastic.logstash.api;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Annotates a Logstash Java plugin. The value returned from {@link #name()} defines the name of the plugin as
 * used in the Logstash pipeline configuration.
 */
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
public @interface LogstashPlugin {

    /**
     * @return Name of the plugin as used in the Logstash pipeline configuration.
     */
    String name();
}

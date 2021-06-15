package org.logstash.log;

import org.apache.logging.log4j.core.Appender;
import org.apache.logging.log4j.core.Core;
import org.apache.logging.log4j.core.Filter;
import org.apache.logging.log4j.core.LogEvent;
import org.apache.logging.log4j.core.appender.AbstractAppender;
import org.apache.logging.log4j.core.config.AppenderControl;
import org.apache.logging.log4j.core.config.Configuration;
import org.apache.logging.log4j.core.config.Node;
import org.apache.logging.log4j.core.config.Property;
import org.apache.logging.log4j.core.config.plugins.Plugin;
import org.apache.logging.log4j.core.config.plugins.PluginBuilderFactory;
import org.apache.logging.log4j.core.config.plugins.PluginNode;

import java.util.Collections;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

/**
 * Appender customization to separate logs per pipeline.
 *
 * It instantiates subappenders, starting from a definition.
 *
 * Sample of XML configuration:
 * <pre>{@code
 *  <PipelineRouting name="a_name">
 *      <RollingFile
 *            name="appender-${ctx:pipeline.id}"
 *            fileName="${sys:ls.logs}/pipeline_${ctx:pipeline.id}.log"
 *            filePattern="${sys:ls.logs}/pipeline_${ctx:pipeline.id}.%i.log.gz">
 *          <PatternLayout>
 *            <pattern>[%d{ISO8601}][%-5p][%-25c] %m%n</pattern>
 *          </PatternLayout>
 *          <SizeBasedTriggeringPolicy size="100MB" />
 *          <DefaultRolloverStrategy max="30" />
 *        </RollingFile>
 *  </PipelineRouting>
 *  }
 * </pre>
 * */
@Plugin(name = "PipelineRouting", category = Core.CATEGORY_NAME, elementType = Appender.ELEMENT_TYPE, printObject = true, deferChildren = true)
public class PipelineRoutingAppender extends AbstractAppender {

    /**
     * Builder for {@link PipelineRoutingAppender} instances
     * */
    public static class Builder<B extends PipelineRoutingAppender.Builder<B>> extends AbstractAppender.Builder<B>
            implements org.apache.logging.log4j.core.util.Builder<PipelineRoutingAppender> {

        @PluginNode
        private Node appenderNode;

        @Override
        public PipelineRoutingAppender build() {
            final String name = getName();
            if (name == null) {
                LOGGER.error("No name defined for this RoutingAppender");
                return null;
            }
            return new PipelineRoutingAppender(name, appenderNode, getConfiguration());
        }
    }

    /**
     * Factory method to instantiate the appender
     * */
    @PluginBuilderFactory
    public static <B extends PipelineRoutingAppender.Builder<B>> B newBuilder() {
        return new PipelineRoutingAppender.Builder<B>().asBuilder();
    }

    private final Node appenderNode;
    private final Configuration configuration;
    private final ConcurrentMap<String, AppenderControl> createdAppenders = new ConcurrentHashMap<>();
    private final Map<String, AppenderControl> createdAppendersUnmodifiableView =
            Collections.unmodifiableMap(createdAppenders);

    protected PipelineRoutingAppender(String name, Node appenderNode, Configuration configuration) {
        super(name, null, null, false, new Property[0]);
        this.appenderNode = appenderNode;
        this.configuration = configuration;
    }

    /**
     * Returns an unmodifiable view of the appenders created by this {@link PipelineRoutingAppender}.
     */
    public Map<String, AppenderControl> getAppenders() {
        return createdAppendersUnmodifiableView;
    }

    /**
     * Core method to apply the logic of routing.
     * */
    @Override
    public void append(LogEvent event) {
        AppenderControl appenderControl = getControl(event);

        if (appenderControl != null) {
            appenderControl.callAppender(event);
        }
    }

    /**
     * Create or retrieve the sub appender for the pipeline.id provided into the event
     * */
    private AppenderControl getControl(LogEvent event) {
        String key = event.getContextData().getValue("pipeline.id");
        if (key == null) {
            LOGGER.debug("Unable to find the pipeline.id in event's context data in routing appender, skip it");
            // this prevent to create an appender when log events are not fish-tagged with pipeline.id,
            // avoid to create log file like "pipeline_${ctx:pipeline.id}.log" which contains duplicated
            // logs from the logstash-* files
            return null;
        }

        AppenderControl appenderControl = createdAppenders.get(key);
        if (appenderControl == null) {
            synchronized (this) {
                appenderControl = createdAppenders.get(key);
                if (appenderControl == null) {
                    //create new appender and control
                    final Appender app = createAppender(event);
                    if (app == null) {
                        return null;
                    }
                    AppenderControl created = new AppenderControl(app, null, null);
                    appenderControl = created;
                    createdAppenders.put(key, created);
                }
            }
        }
        return appenderControl;
    }


    /**
     * Used by @{@link #getControl(LogEvent)} to create new subappenders for not yet encountered pipelines.
     * */
    private Appender createAppender(final LogEvent event) {
        for (final Node node : appenderNode.getChildren()) {
            if (node.getType().getElementName().equals(Appender.ELEMENT_TYPE)) {
                final Node appNode = new Node(node);
                configuration.createConfiguration(appNode, event);
                if (appNode.getObject() instanceof Appender) {
                    final Appender app = appNode.getObject();
                    app.start();
                    return app;
                }
                error("Unable to create Appender of type " + node.getName());
                return null;
            }
        }
        error("No Appender was configured for  " + getName());
        return null;
    }

}

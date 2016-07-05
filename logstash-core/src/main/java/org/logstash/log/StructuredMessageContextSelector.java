package org.logstash.log;

import org.apache.logging.log4j.core.Logger;
import org.apache.logging.log4j.core.LoggerContext;
import org.apache.logging.log4j.core.selector.ClassLoaderContextSelector;
import org.apache.logging.log4j.message.MessageFactory;

import java.net.URI;

public class StructuredMessageContextSelector extends ClassLoaderContextSelector {

    @Override
    protected LoggerContext createContext(String name, URI configuration) {
        return new StructuredMessageContext(name, null, configuration);
    }

    private class StructuredMessageContext extends LoggerContext {

        StructuredMessageContext(String name, Object externContext, URI configuration) {
            super(name, null, configuration);
        }

        @Override
        protected Logger newInstance(final LoggerContext ctx, final String name, MessageFactory messageFactory)
        {
            if (null == messageFactory)
                messageFactory = StructuredMessageFactory.INSTANCE;

            return super.newInstance(ctx, name, messageFactory);
        }

    }
}

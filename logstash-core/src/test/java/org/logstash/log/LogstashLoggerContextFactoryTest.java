package org.logstash.log;


import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.apache.logging.log4j.spi.LoggerContext;
import org.apache.logging.log4j.spi.LoggerContextFactory;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.runners.MockitoJUnitRunner;
import static org.mockito.Mockito.verifyZeroInteractions;
import static org.mockito.Mockito.verify;

import java.net.URI;


import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit test for {@link LogstashLoggerContextFactory}
 */
@RunWith(MockitoJUnitRunner.class)
public class LogstashLoggerContextFactoryTest {

    @Mock
    private LoggerContext preEstablishedContext;

    private LogstashLoggerContextFactory contextFactory;

    @Before
    public void setup() {
        contextFactory = new LogstashLoggerContextFactory(preEstablishedContext);
    }

    @Test
    public void testGetContextAlwaysReturnsTheSameObject() {
        assertThat(contextFactory.getContext("", ClassLoader.getSystemClassLoader(), null, false))
                .isEqualTo(contextFactory.getContext("someRandomValue", null, null, false))
                .isEqualTo(contextFactory.getContext("someOtherRandomValue", ClassLoader.getSystemClassLoader(), null, false, URI.create("foo"), "name"));
    }
}
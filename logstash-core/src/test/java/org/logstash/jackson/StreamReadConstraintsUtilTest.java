package org.logstash.jackson;

import com.fasterxml.jackson.core.StreamReadConstraints;
import org.apache.logging.log4j.Logger;
import org.apache.logging.log4j.core.LogEvent;
import org.apache.logging.log4j.junit.LoggerContextRule;
import org.apache.logging.log4j.test.appender.ListAppender;
import org.junit.Before;
import org.junit.ClassRule;
import org.junit.Test;

import java.util.Arrays;
import java.util.List;
import java.util.Properties;
import java.util.function.BiConsumer;
import org.apache.logging.log4j.Level;

import static org.assertj.core.api.Assertions.*;
import static org.logstash.jackson.StreamReadConstraintsUtil.Override.*;

public class StreamReadConstraintsUtilTest {

    @ClassRule
    public static final LoggerContextRule LOGGER_CONTEXT_RULE = new LoggerContextRule("log4j2-log-stream-read-constraints.xml");

    private ListAppender listAppender;
    private Logger observedLogger;

    private static final int DEFAULT_MAX_STRING_LENGTH = 200_000_000;
    private static final int DEFAULT_MAX_NUMBER_LENGTH = 10_000;
    private static final int DEFAULT_MAX_NESTING_DEPTH = 1_000;

    @Before
    public void setUpLoggingListAppender() {
        int i = 1+16;
        this.observedLogger = LOGGER_CONTEXT_RULE.getLogger(StreamReadConstraintsUtil.class);
        this.listAppender = LOGGER_CONTEXT_RULE.getListAppender("EventListAppender").clear();
    }

    @Test
    public void configuresDefaultsByDefault() {
        StreamReadConstraintsUtil.fromSystemProperties().validateIsGlobalDefault();
    }

    @Test
    public void configuresMaxStringLength() {
        final Properties properties = new Properties();
        properties.setProperty(MAX_STRING_LENGTH.propertyName, "10101");

        fromProperties(properties, (configuredUtil, defaults) -> {
            final StreamReadConstraints configuredConstraints = configuredUtil.get();

            assertThat(configuredConstraints).returns(10101, from(StreamReadConstraints::getMaxStringLength));

            assertThat(configuredConstraints).as("inherited defaults")
                    .returns(defaults.getMaxDocumentLength(), from(StreamReadConstraints::getMaxDocumentLength))
                    .returns(defaults.getMaxNameLength(), from(StreamReadConstraints::getMaxNameLength))
                    .returns(DEFAULT_MAX_NESTING_DEPTH, from(StreamReadConstraints::getMaxNestingDepth))
                    .returns(DEFAULT_MAX_NUMBER_LENGTH, from(StreamReadConstraints::getMaxNumberLength));

            assertThatThrownBy(configuredUtil::validateIsGlobalDefault).isInstanceOf(IllegalStateException.class).hasMessageContaining(MAX_STRING_LENGTH.propertyName);

            configuredUtil.applyAsGlobalDefault();
            assertThatCode(configuredUtil::validateIsGlobalDefault).doesNotThrowAnyException();
        });
    }

    @Test
    public void configuresMaxStringLengthInvalid() {
        final Properties properties = new Properties();
        properties.setProperty(MAX_STRING_LENGTH.propertyName, "NaN");

        fromProperties(properties, (configuredUtil, defaults) -> assertThatThrownBy(configuredUtil::get)
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining(MAX_STRING_LENGTH.propertyName));
    }

    @Test
    public void configuresMaxStringLengthNegative() {
        final Properties properties = new Properties();
        properties.setProperty(MAX_STRING_LENGTH.propertyName, "-1000");

        fromProperties(properties, (configuredUtil, defaults) -> assertThatThrownBy(configuredUtil::get)
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining(MAX_STRING_LENGTH.propertyName));
    }

    @Test
    public void configuresMaxNumberLength() {
        final Properties properties = new Properties();
        properties.setProperty(MAX_NUMBER_LENGTH.propertyName, "101");

        fromProperties(properties, (configuredUtil, defaults) -> {
            final StreamReadConstraints configuredConstraints = configuredUtil.get();

            assertThat(configuredConstraints).returns(101, from(StreamReadConstraints::getMaxNumberLength));

            assertThat(configuredConstraints).as("inherited defaults")
                    .returns(defaults.getMaxDocumentLength(), from(StreamReadConstraints::getMaxDocumentLength))
                    .returns(defaults.getMaxNameLength(), from(StreamReadConstraints::getMaxNameLength))
                    .returns(DEFAULT_MAX_NESTING_DEPTH, from(StreamReadConstraints::getMaxNestingDepth))
                    .returns(DEFAULT_MAX_STRING_LENGTH, from(StreamReadConstraints::getMaxStringLength));

            assertThatThrownBy(configuredUtil::validateIsGlobalDefault).isInstanceOf(IllegalStateException.class).hasMessageContaining(MAX_NUMBER_LENGTH.propertyName);

            configuredUtil.applyAsGlobalDefault();
            assertThatCode(configuredUtil::validateIsGlobalDefault).doesNotThrowAnyException();
        });
    }

    @Test
    public void configuresMaxNumberLengthInvalid() {
        final Properties properties = new Properties();
        properties.setProperty(MAX_NUMBER_LENGTH.propertyName, "NaN");

        fromProperties(properties, (configuredUtil, defaults) -> assertThatThrownBy(configuredUtil::get)
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining(MAX_NUMBER_LENGTH.propertyName));
    }

    @Test
    public void configuresMaxNumberLengthNegative() {
        final Properties properties = new Properties();
        properties.setProperty(MAX_NUMBER_LENGTH.propertyName, "-1000");

        fromProperties(properties, (configuredUtil, defaults) -> assertThatThrownBy(configuredUtil::get)
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining(MAX_NUMBER_LENGTH.propertyName));
    }

    @Test
    public void configuresMaxNestingDepth() {
        final Properties properties = new Properties();
        properties.setProperty(MAX_NESTING_DEPTH.propertyName, "101");

        fromProperties(properties, (configuredUtil, defaults) -> {
            final StreamReadConstraints configuredConstraints = configuredUtil.get();

            assertThat(configuredConstraints).returns(101, from(StreamReadConstraints::getMaxNestingDepth));

            assertThat(configuredConstraints).as("inherited defaults")
                    .returns(defaults.getMaxDocumentLength(), from(StreamReadConstraints::getMaxDocumentLength))
                    .returns(defaults.getMaxNameLength(), from(StreamReadConstraints::getMaxNameLength))
                    .returns(DEFAULT_MAX_STRING_LENGTH, from(StreamReadConstraints::getMaxStringLength))
                    .returns(DEFAULT_MAX_NUMBER_LENGTH, from(StreamReadConstraints::getMaxNumberLength));

            assertThatThrownBy(configuredUtil::validateIsGlobalDefault).isInstanceOf(IllegalStateException.class).hasMessageContaining(MAX_NESTING_DEPTH.propertyName);

            configuredUtil.applyAsGlobalDefault();
            assertThatCode(configuredUtil::validateIsGlobalDefault).doesNotThrowAnyException();
        });
    }

    @Test
    public void configuresMaxNestingDepthInvalid() {
        final Properties properties = new Properties();
        properties.setProperty(MAX_NESTING_DEPTH.propertyName, "NaN");

        fromProperties(properties, (configuredUtil, defaults) -> assertThatThrownBy(configuredUtil::get)
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining(MAX_NESTING_DEPTH.propertyName));
    }

    @Test
    public void configuresMaxNestingDepthNegative() {
        final Properties properties = new Properties();
        properties.setProperty(MAX_NESTING_DEPTH.propertyName, "-1000");

        fromProperties(properties, (configuredUtil, defaults) -> assertThatThrownBy(configuredUtil::get)
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining(MAX_NESTING_DEPTH.propertyName));
    }

    @Test
    public void validatesApplication() {
        final Properties properties = new Properties();
        properties.setProperty(PROP_PREFIX + "unsupported-option1", "100");
        properties.setProperty(PROP_PREFIX + "unsupported-option2", "100");
        properties.setProperty(MAX_NESTING_DEPTH.propertyName, "1010");
        properties.setProperty(MAX_STRING_LENGTH.propertyName, "1011");
        properties.setProperty(MAX_NUMBER_LENGTH.propertyName, "1110");

        System.out.format("START%n");

        fromProperties(properties, (configuredUtil, defaults) -> {
            configuredUtil.applyAsGlobalDefault();
            configuredUtil.validateIsGlobalDefault();
        });

        System.out.format("OK%n");

        assertLogObserved(Level.INFO, "override `" + MAX_NESTING_DEPTH.propertyName + "` configured to `1010`");
        assertLogObserved(Level.INFO, "override `" + MAX_STRING_LENGTH.propertyName + "` configured to `1011`");
        assertLogObserved(Level.INFO, "override `" + MAX_NUMBER_LENGTH.propertyName + "` configured to `1110`");

        assertLogObserved(Level.WARN, "override `" + PROP_PREFIX + "unsupported-option1` is unknown and has been ignored");
        assertLogObserved(Level.WARN, "override `" + PROP_PREFIX + "unsupported-option1` is unknown and has been ignored");
    }

    @Test
    public void usesJacksonDefaultsWhenNoConfig() {
        StreamReadConstraintsUtil util = new StreamReadConstraintsUtil(new Properties(), this.observedLogger);
        StreamReadConstraints constraints = util.get();

        assertThat(constraints)
            .returns(DEFAULT_MAX_STRING_LENGTH, from(StreamReadConstraints::getMaxStringLength))
            .returns(DEFAULT_MAX_NUMBER_LENGTH, from(StreamReadConstraints::getMaxNumberLength))
            .returns(DEFAULT_MAX_NESTING_DEPTH, from(StreamReadConstraints::getMaxNestingDepth));
    }

    @Test
    public void configOverridesDefault() {
        Properties props = new Properties();
        props.setProperty("logstash.jackson.stream-read-constraints.max-string-length", "100");

        StreamReadConstraintsUtil util = new StreamReadConstraintsUtil(props, this.observedLogger);
        StreamReadConstraints constraints = util.get();

        assertThat(constraints)
            .returns(100, from(StreamReadConstraints::getMaxStringLength))
            .returns(DEFAULT_MAX_NUMBER_LENGTH, from(StreamReadConstraints::getMaxNumberLength))
            .returns(DEFAULT_MAX_NESTING_DEPTH, from(StreamReadConstraints::getMaxNestingDepth));
    }

    private void assertLogObserved(final Level level, final String... messageFragments) {
        List<LogEvent> logEvents = listAppender.getEvents();
        assertThat(logEvents)
                .withFailMessage("Expected %s to contain a %s-level log event containing %s", logEvents, level, Arrays.toString(messageFragments))
                .filteredOn(logEvent -> logEvent.getLevel().equals(level))
                .anySatisfy(logEvent -> assertThat(logEvent.getMessage().getFormattedMessage()).contains(messageFragments));
    }

    private synchronized void fromProperties(final Properties properties, BiConsumer<StreamReadConstraintsUtil, StreamReadConstraints> defaultsConsumer) {
        final StreamReadConstraints defaults = StreamReadConstraints.defaults();
        try {
            final StreamReadConstraintsUtil util = new StreamReadConstraintsUtil(properties, this.observedLogger);
            defaultsConsumer.accept(util, defaults);
        } finally {
            StreamReadConstraints.overrideDefaultStreamReadConstraints(defaults);
        }
    }
}
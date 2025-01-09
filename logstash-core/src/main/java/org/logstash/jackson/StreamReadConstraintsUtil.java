package org.logstash.jackson;

import com.fasterxml.jackson.core.StreamReadConstraints;
import com.google.common.collect.Sets;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import javax.annotation.Nullable;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Properties;
import java.util.Set;
import java.util.function.BiConsumer;
import java.util.stream.Collectors;

public class StreamReadConstraintsUtil {

    private final Map<String,String> propertyOverrides;
    private final Logger logger;

    private StreamReadConstraints configuredStreamReadConstraints;

    enum Override {
        MAX_STRING_LENGTH(200_000_000, StreamReadConstraints.Builder::maxStringLength, StreamReadConstraints::getMaxStringLength),
        MAX_NUMBER_LENGTH(10_000, StreamReadConstraints.Builder::maxNumberLength, StreamReadConstraints::getMaxNumberLength),
        MAX_NESTING_DEPTH(1_000, StreamReadConstraints.Builder::maxNestingDepth, StreamReadConstraints::getMaxNestingDepth),
        ;

        static final String PROP_PREFIX = "logstash.jackson.stream-read-constraints.";

        final String propertyName;
        final int defaultValue;
        private final IntValueApplicator applicator;
        private final IntValueObserver observer;

        Override(final int defaultValue,
                 final IntValueApplicator applicator,
                 final IntValueObserver observer) {
            this.propertyName = PROP_PREFIX + this.name().toLowerCase().replace('_', '-');
            this.defaultValue = defaultValue;
            this.applicator = applicator;
            this.observer = observer;
        }

        int resolve(final Integer specifiedValue) {
            return Objects.requireNonNullElse(specifiedValue, defaultValue);
        }

        void apply(final StreamReadConstraints.Builder constraintsBuilder,
                   @Nullable final Integer specifiedValue) {
            this.applicator.applyIntValue(constraintsBuilder, resolve(specifiedValue));
        }

        int observe(final StreamReadConstraints constraints) {
            return this.observer.observeIntValue(constraints);
        }

        @FunctionalInterface
        interface IntValueObserver {
            int observeIntValue(final StreamReadConstraints constraints);
        }

        @FunctionalInterface
        interface IntValueApplicator {
            @SuppressWarnings("UnusedReturnValue")
            StreamReadConstraints.Builder applyIntValue(final StreamReadConstraints.Builder constraintsBuilder, final int value);
        }
    }

    /**
     * @return an instance configured by {@code System.getProperties()}
     */
    public static StreamReadConstraintsUtil fromSystemProperties() {
        return new StreamReadConstraintsUtil(System.getProperties());
    }

    StreamReadConstraintsUtil(final Properties properties) {
        this(properties, null);
    }

    StreamReadConstraintsUtil(final Properties properties,
                              final Logger logger) {
        this(extractProperties(properties), logger);
    }

    static private Map<String,String> extractProperties(final Properties properties) {
        return properties.stringPropertyNames().stream()
                .filter(propName -> propName.startsWith(Override.PROP_PREFIX))
                .map(propName -> Map.entry(propName, properties.getProperty(propName)))
                .filter(entry -> entry.getValue() != null)
                .collect(Collectors.toUnmodifiableMap(Map.Entry::getKey, Map.Entry::getValue));
    }

    private StreamReadConstraintsUtil(final Map<String,String> propertyOverrides,
                              final Logger logger) {
        this.propertyOverrides = Map.copyOf(propertyOverrides);
        this.logger = Objects.requireNonNullElseGet(logger, () -> LogManager.getLogger(StreamReadConstraintsUtil.class));
    }

    StreamReadConstraints get() {
        if (configuredStreamReadConstraints == null) {
            final StreamReadConstraints.Builder builder = StreamReadConstraints.defaults().rebuild();

            eachOverride((override, specifiedValue) -> override.apply(builder, specifiedValue));

            this.configuredStreamReadConstraints = builder.build();
        }
        return configuredStreamReadConstraints;
    }

    public void applyAsGlobalDefault() {
        StreamReadConstraints.overrideDefaultStreamReadConstraints(get());
    }

    public void validateIsGlobalDefault() {
        validate(StreamReadConstraints.defaults());
    }

    public void validate(final StreamReadConstraints streamReadConstraints) {
        final List<String> fatalIssues = new ArrayList<>();
        eachOverride((override, specifiedValue) -> {
            final int effectiveValue = override.observe(streamReadConstraints);
            final int expectedValue = override.resolve(specifiedValue);

            if (!Objects.equals(effectiveValue, expectedValue)) {
                fatalIssues.add(String.format("`%s` (expected: `%s`, actual: `%s`)", override.propertyName, expectedValue, effectiveValue));
            } else {
                final String reason = Objects.nonNull(specifiedValue) ? "system properties" : "logstash default";
                logger.info("Jackson default value override `{}` configured to `{}` ({})", override.propertyName, effectiveValue, reason);
            }
        });
        for (String unsupportedProperty : getUnsupportedProperties()) {
            logger.warn("Jackson default value override `{}` is unknown and has been ignored", unsupportedProperty);
        }
        if (!fatalIssues.isEmpty()) {
            throw new IllegalStateException(String.format("Jackson default values not applied: %s", String.join(",", fatalIssues)));
        }
    }

    void eachOverride(BiConsumer<Override,Integer> overrideIntegerBiConsumer) {
        for (Override override : Override.values()) {
            final String propValue = this.propertyOverrides.get(override.propertyName);

            try {
                final Integer explicitValue = Optional.ofNullable(propValue)
                        .map(Integer::parseInt)
                        .orElse(null);
                overrideIntegerBiConsumer.accept(override, explicitValue);
            } catch (IllegalArgumentException e) {
                throw new IllegalArgumentException(String.format("System property `%s` must be positive integer value. Received: `%s`", override.propertyName, propValue), e);
            }
        }
    }

    Set<String> getUnsupportedProperties() {
        Set<String> supportedProps = Arrays.stream(Override.values()).map(p -> p.propertyName).collect(Collectors.toSet());
        Set<String> providedProps = this.propertyOverrides.keySet();

        return Sets.difference(providedProps, supportedProps);
    }
}

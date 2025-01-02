package org.logstash.jackson;

import com.fasterxml.jackson.core.StreamReadConstraints;
import com.google.common.collect.Sets;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.*;
import java.util.function.BiConsumer;
import java.util.function.BiFunction;
import java.util.function.Function;
import java.util.stream.Collectors;

public class StreamReadConstraintsUtil {

    private final Map<String,String> propertyOverrides;
    private final Logger logger;

    private StreamReadConstraints configuredStreamReadConstraints;

    // Provide default values for Jackson constraints in the case they are
    // not specified in configuration file.
    private static final Map<Override, Integer> JACKSON_DEFAULTS = Map.of(
        Override.MAX_STRING_LENGTH, 200_000_000,
        Override.MAX_NUMBER_LENGTH, 10_000,
        Override.MAX_NESTING_DEPTH, 1_000
    );

    enum Override {
        MAX_STRING_LENGTH(StreamReadConstraints.Builder::maxStringLength, StreamReadConstraints::getMaxStringLength),
        MAX_NUMBER_LENGTH(StreamReadConstraints.Builder::maxNumberLength, StreamReadConstraints::getMaxNumberLength),
        MAX_NESTING_DEPTH(StreamReadConstraints.Builder::maxNestingDepth, StreamReadConstraints::getMaxNestingDepth),
        ;

        static final String PROP_PREFIX = "logstash.jackson.stream-read-constraints.";

        final String propertyName;
        private final IntValueApplicator applicator;
        private final IntValueObserver observer;

        Override(final IntValueApplicator applicator,
                 final IntValueObserver observer) {
            this.propertyName = PROP_PREFIX + this.name().toLowerCase().replace('_', '-');
            this.applicator = applicator;
            this.observer = observer;
        }

        @FunctionalInterface
        interface IntValueObserver extends Function<StreamReadConstraints, Integer> {}

        @FunctionalInterface
        interface IntValueApplicator extends BiFunction<StreamReadConstraints.Builder, Integer, StreamReadConstraints.Builder> {}
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

            // Apply the Jackson defaults first, then the overrides from config
            JACKSON_DEFAULTS.forEach((override, value) -> override.applicator.apply(builder, value));
            eachOverride((override, value) -> override.applicator.apply(builder, value));

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

    private void validate(final StreamReadConstraints streamReadConstraints) {
        final List<String> fatalIssues = new ArrayList<>();
        eachOverride((override, specifiedValue) -> {
            final Integer effectiveValue = override.observer.apply(streamReadConstraints);
            if (Objects.equals(specifiedValue, effectiveValue)) {
                logger.info("Jackson default value override `{}` configured to `{}`", override.propertyName, specifiedValue);
            } else {
                fatalIssues.add(String.format("`%s` (expected: `%s`, actual: `%s`)", override.propertyName, specifiedValue, effectiveValue));
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
            if (propValue != null) {
                try {
                    int intValue = Integer.parseInt(propValue);
                    overrideIntegerBiConsumer.accept(override, intValue);
                } catch (IllegalArgumentException e) {
                    throw new IllegalArgumentException(String.format("System property `%s` must be positive integer value. Received: `%s`", override.propertyName, propValue), e);
                }
            }
        }
    }

    Set<String> getUnsupportedProperties() {
        Set<String> supportedProps = Arrays.stream(Override.values()).map(p -> p.propertyName).collect(Collectors.toSet());
        Set<String> providedProps = this.propertyOverrides.keySet();

        return Sets.difference(providedProps, supportedProps);
    }
}

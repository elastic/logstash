package co.elastic.logstash.api;

import java.util.function.Function;

/**
 * A custom metric.
 * @param <VALUE_TYPE> must be jackson-serializable.
 *
 * NOTE: this interface is experimental and considered internal.
 *       Its shape may change from one Logstash release to the next.
 */
public interface UserMetric<VALUE_TYPE> {
    VALUE_TYPE getValue();

    /**
     * A {@link UserMetric.Factory<USER_METRIC>} is the primary way to register a custom user-metric
     * along-side a null implementation for performance when metrics are disabled.
     *
     * @param <USER_METRIC> a sub-interface of {@link UserMetric}
     */
    interface Factory<USER_METRIC extends UserMetric<?>> {
        Class<USER_METRIC> getType();
        USER_METRIC create(String name);
        USER_METRIC nullImplementation();
    }

    /**
     * A {@link UserMetric.Provider} is an intermediate helper type meant to be statically available by any
     * user-provided {@link UserMetric} interface, encapsulating its null implementation and providing
     * a way to simply get a {@link UserMetric.Factory} for a given non-null implementation.
     *
     * @param <USER_METRIC> an interface that extends {@link UserMetric}.
     */
    class Provider<USER_METRIC extends UserMetric<?>> {
        private final Class<USER_METRIC> type;
        private final USER_METRIC nullImplementation;

        public Provider(final Class<USER_METRIC> type, final USER_METRIC nullImplementation) {
            assert type.isInterface() : String.format("type must be an interface, got %s", type);

            this.type = type;
            this.nullImplementation = nullImplementation;
        }

        public Factory<USER_METRIC> getFactory(final Function<String, USER_METRIC> supplier) {
            return new Factory<USER_METRIC>() {
                @Override
                public USER_METRIC create(final String name) {
                    return supplier.apply(name);
                }

                @Override
                public Class<USER_METRIC> getType() {
                    return type;
                }

                @Override
                public USER_METRIC nullImplementation() {
                    return nullImplementation;
                }
            };
        }
    }
}

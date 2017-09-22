package org.logstash;

/**
 * Exception thrown by {@link Javafier}, {@link Rubyfier} and {@link Valuefier} if trying to convert
 * an illegal argument type.
 */
final class MissingConverterException extends RuntimeException {

    private static final long serialVersionUID = 1L;

    MissingConverterException(final Class<?> cls) {
        super(
            String.format(
                "Missing Converter handling for full class name=%s, simple name=%s",
                cls.getName(), cls.getSimpleName()
            )
        );
    }
}

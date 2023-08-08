package org.logstash.util;

import org.hamcrest.Matchers;
import org.junit.Assert;

@FunctionalInterface
public interface ExceptionMatcher {
    void execute() throws Throwable;

    static <T extends Throwable> T assertThrows(Class<T> expectedType, ExceptionMatcher executable) {
        try {
            executable.execute();
        } catch (Throwable actual) {
            Assert.assertThat(actual, Matchers.instanceOf(expectedType));
            return expectedType.cast(actual);
        }

        throw new AssertionError(String.format("Expected %s to be thrown, but nothing was thrown.", expectedType.getName()));
    }
}
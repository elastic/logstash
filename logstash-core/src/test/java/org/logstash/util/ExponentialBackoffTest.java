package org.logstash.util;

import org.assertj.core.api.Assertions;
import org.junit.Test;
import org.mockito.Mockito;

import java.io.IOException;

public class ExponentialBackoffTest {
    @Test
    public void testWithoutException() throws Exception {
        ExponentialBackoff backoff = new ExponentialBackoff(1L);
        CheckedSupplier<Integer> supplier = () -> 1 + 1;
        Assertions.assertThatCode(() -> backoff.retryable(supplier)).doesNotThrowAnyException();
        Assertions.assertThat(backoff.retryable(supplier)).isEqualTo(2);
    }

    @Test
    @SuppressWarnings("unchecked")
    public void testOneException() throws Exception {
        ExponentialBackoff backoff = new ExponentialBackoff(1L);
        CheckedSupplier<Boolean> supplier = Mockito.mock(CheckedSupplier.class);
        Mockito.when(supplier.get()).thenThrow(new IOException("can't write to disk")).thenReturn(true);
        Boolean b = backoff.retryable(supplier);
        Assertions.assertThat(b).isEqualTo(true);
    }

    @Test
    @SuppressWarnings("unchecked")
    public void testExceptionsReachMaxRetry() throws Exception {
        ExponentialBackoff backoff = new ExponentialBackoff(2L);
        CheckedSupplier<Boolean> supplier = Mockito.mock(CheckedSupplier.class);
        Mockito.when(supplier.get()).thenThrow(new IOException("can't write to disk"));
        Assertions.assertThatThrownBy(() -> backoff.retryable(supplier))
                .isInstanceOf(ExponentialBackoff.RetryException.class)
                .hasMessageContaining("max retry");
    }

}
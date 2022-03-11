package org.logstash.util;

import org.assertj.core.api.Assertions;
import org.junit.Test;
import org.mockito.Mockito;

import java.io.IOException;

public class ExponentialBackoffTest {
    @Test
    public void testSupplier() throws Exception {
        ExponentialBackoff backoff = new ExponentialBackoff(1L);
        CheckedSupplier<Integer> supplier = () -> 1 + 1;
        Assertions.assertThatCode(() -> backoff.retry(supplier)).doesNotThrowAnyException();
        Assertions.assertThat(backoff.retry(supplier)).isEqualTo(2);
    }

    @Test
    @SuppressWarnings("unchecked")
    public void testSupplierWithOneException() throws Exception {
        ExponentialBackoff backoff = new ExponentialBackoff(1L);
        CheckedSupplier<Boolean> supplier = Mockito.mock(CheckedSupplier.class);
        Mockito.when(supplier.get()).thenThrow(new IOException("can't write to disk")).thenReturn(true);
        Boolean b = backoff.retry(supplier);
        Assertions.assertThat(b).isEqualTo(true);
    }

    @Test
    @SuppressWarnings("unchecked")
    public void testSupplierWithException() throws Exception {
        ExponentialBackoff backoff = new ExponentialBackoff(2L);
        CheckedSupplier<Boolean> supplier = Mockito.mock(CheckedSupplier.class);
        Mockito.when(supplier.get()).thenThrow(new IOException("can't write to disk"));
        Assertions.assertThatThrownBy(() -> backoff.retry(supplier))
                .isInstanceOf(ExponentialBackoff.RetryException.class)
                .hasMessageContaining("max retry");
    }

}
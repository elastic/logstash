package org.logstash.instrument.metrics;

import org.junit.Assert;
import org.junit.Test;

import java.util.HashMap;
import java.util.Map;
import java.util.function.BiConsumer;

public class MetricsUtilTest {

    @Test
    public void testApplyFractionWithValidRates() {
        final Map<String, Double> rates = new HashMap<String, Double>();
        rates.put("current", 0.12);
        rates.put("lifetime", 1.3);

        final Number fraction = 3;

        Map<String, Double> fracturedRates = MetricsUtil.applyFraction(rates, fraction);
        fracturedRates.forEach(new BiConsumer<String, Double>() {
            @Override
            public void accept(String key, Double value) {
                Double origin = MetricsUtil.toPercentage(fraction, rates.get(key) * fraction.doubleValue()) ;
                Assert.assertEquals(origin, value);
            }
        });
    }

    // test when rates initially will be null or infinity
    @Test
    public void testApplyFractionWithInvalidRates() {
        final Map<String, Double> rates = new HashMap<String, Double>();
        rates.put("current", null);
        rates.put("lifetime", 0.0);

        final Number fraction = 3;
        final Double expected = 0.0d;

        Map<String, Double> fracturedRates = MetricsUtil.applyFraction(rates, fraction);
        fracturedRates.forEach(new BiConsumer<String, Double>() {
            @Override
            public void accept(String key, Double value) {
                Assert.assertEquals(expected, value);
            }
        });
    }

    @Test
    public void testIsValueUndefined() {
        Assert.assertTrue(MetricsUtil.isValueUndefined(null));
        Assert.assertTrue(MetricsUtil.isValueUndefined(Double.NaN));
        Assert.assertTrue(MetricsUtil.isValueUndefined(Double.NEGATIVE_INFINITY));
        Assert.assertFalse(MetricsUtil.isValueUndefined(0.1d));
        Assert.assertFalse(MetricsUtil.isValueUndefined(100.0d));
    }
}
/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.logstash.util;

import org.junit.Test;

import java.math.BigInteger;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertThrows;

public class ByteValueTest {

    // parse() tests for all units
    @Test
    public void testParseBytes() {
        assertEquals(BigInteger.valueOf(100L), ByteValue.parse("100b"));
        assertEquals(BigInteger.valueOf(1L), ByteValue.parse("1b"));
        assertEquals(BigInteger.valueOf(0L), ByteValue.parse("0b"));
    }

    @Test
    public void testParseKilobytes() {
        assertEquals(BigInteger.valueOf(100L * (1L << 10)), ByteValue.parse("100kb"));
        assertEquals(BigInteger.valueOf(100L * (1L << 10)), ByteValue.parse("100k"));
        assertEquals(BigInteger.valueOf(1L << 10), ByteValue.parse("1kb"));
    }

    @Test
    public void testParseMegabytes() {
        assertEquals(BigInteger.valueOf(100L * (1L << 20)), ByteValue.parse("100mb"));
        assertEquals(BigInteger.valueOf(100L * (1L << 20)), ByteValue.parse("100m"));
        assertEquals(BigInteger.valueOf(1L << 20), ByteValue.parse("1mb"));
    }

    @Test
    public void testParseGigabytes() {
        assertEquals(BigInteger.valueOf(100L * (1L << 30)), ByteValue.parse("100gb"));
        assertEquals(BigInteger.valueOf(100L * (1L << 30)), ByteValue.parse("100g"));
        assertEquals(BigInteger.valueOf(1L << 30), ByteValue.parse("1gb"));
    }

    @Test
    public void testParseTerabytes() {
        assertEquals(BigInteger.valueOf(100L * (1L << 40)), ByteValue.parse("100tb"));
        assertEquals(BigInteger.valueOf(100L * (1L << 40)), ByteValue.parse("100t"));
        assertEquals(BigInteger.valueOf(1L << 40), ByteValue.parse("1tb"));
    }

    @Test
    public void testParsePetabytes() {
        assertEquals(BigInteger.valueOf(100L * (1L << 50)), ByteValue.parse("100pb"));
        assertEquals(BigInteger.valueOf(100L * (1L << 50)), ByteValue.parse("100p"));
        assertEquals(BigInteger.valueOf(1L << 50), ByteValue.parse("1pb"));
    }

    @Test
    public void testParseCaseInsensitive() {
        assertEquals(BigInteger.valueOf(100L * (1L << 20)), ByteValue.parse("100MB"));
        assertEquals(BigInteger.valueOf(100L * (1L << 20)), ByteValue.parse("100Mb"));
        assertEquals(BigInteger.valueOf(100L * (1L << 30)), ByteValue.parse("100GB"));
    }

    @Test
    public void testParseDecimalNumbers() {
        assertEquals(BigInteger.valueOf((long) (1.5 * (1L << 20))), ByteValue.parse("1.5mb"));
        assertEquals(BigInteger.valueOf((long) (2.5 * (1L << 30))), ByteValue.parse("2.5gb"));
        assertEquals(BigInteger.valueOf((long) (0.5 * (1L << 10))), ByteValue.parse("0.5kb"));
    }

    @Test
    public void testParseLargeNumbers() {
        // Test values that exceed Long.MAX_VALUE (matching Ruby's BigNum behavior)
        BigInteger largeNumber = new BigInteger("100000000000"); // 10^11
        BigInteger pbMultiplier = BigInteger.valueOf(1L << 50);
        BigInteger expected = largeNumber.multiply(pbMultiplier);
        assertEquals(expected, ByteValue.parse("100000000000pb"));
    }

    @Test
    public void testParseThrowsForUnknownUnit() {
        Exception thrownException = assertThrows(org.jruby.exceptions.ArgumentError.class, () -> {
            ByteValue.parse("100xyz");
        });
        assertThat(thrownException.getMessage(), containsString("Unknown bytes value '100xyz'"));
    }

    @Test
    public void testParseThrowsForNoUnit() {
        Exception thrownException = assertThrows(org.jruby.exceptions.ArgumentError.class, () -> {
            ByteValue.parse("100");
        });
        assertThat(thrownException.getMessage(), containsString("Unknown bytes value '100'"));
    }

    // multiplier() tests
    @Test
    public void testMultiplierBytes() {
        assertEquals(ByteValue.B, ByteValue.multiplier("100b"));
        assertEquals(ByteValue.B, ByteValue.multiplier("b"));
    }

    @Test
    public void testMultiplierKilobytes() {
        assertEquals(ByteValue.KB, ByteValue.multiplier("100kb"));
        assertEquals(ByteValue.KB, ByteValue.multiplier("100k"));
    }

    @Test
    public void testMultiplierMegabytes() {
        assertEquals(ByteValue.MB, ByteValue.multiplier("100mb"));
        assertEquals(ByteValue.MB, ByteValue.multiplier("100m"));
    }

    @Test
    public void testMultiplierGigabytes() {
        assertEquals(ByteValue.GB, ByteValue.multiplier("100gb"));
        assertEquals(ByteValue.GB, ByteValue.multiplier("100g"));
    }

    @Test
    public void testMultiplierTerabytes() {
        assertEquals(ByteValue.TB, ByteValue.multiplier("100tb"));
        assertEquals(ByteValue.TB, ByteValue.multiplier("100t"));
    }

    @Test
    public void testMultiplierPetabytes() {
        assertEquals(ByteValue.PB, ByteValue.multiplier("100pb"));
        assertEquals(ByteValue.PB, ByteValue.multiplier("100p"));
    }

    @Test
    public void testMultiplierThrowsForUnknownUnit() {
        Exception thrownException = assertThrows(org.jruby.exceptions.ArgumentError.class, () -> {
            ByteValue.multiplier("unknown");
        });
        assertThat(thrownException.getMessage(), containsString("Unknown bytes value 'unknown'"));
    }

    // humanReadable() tests
    @Test
    public void testHumanReadableBytes() {
        assertEquals("01b", ByteValue.humanReadable(1L));
        assertEquals("100b", ByteValue.humanReadable(100L));
    }

    @Test
    public void testHumanReadableKilobytes() {
        // Note: uses strict > comparison, so exactly 1KB shows as bytes
        assertEquals("1024b", ByteValue.humanReadable(1L << 10));
        // Just over 1KB shows as kb
        assertEquals("01kb", ByteValue.humanReadable((1L << 10) + 1));
        assertEquals("10kb", ByteValue.humanReadable(10L * (1L << 10) + 1));
    }

    @Test
    public void testHumanReadableMegabytes() {
        // Note: uses strict > comparison, so exactly 1MB shows as kb
        assertEquals("1024kb", ByteValue.humanReadable(1L << 20));
        // Just over 1MB shows as mb
        assertEquals("01mb", ByteValue.humanReadable((1L << 20) + 1));
        assertEquals("10mb", ByteValue.humanReadable(10L * (1L << 20) + 1));
    }

    @Test
    public void testHumanReadableGigabytes() {
        // Note: uses strict > comparison, so exactly 1GB shows as mb
        assertEquals("1024mb", ByteValue.humanReadable(1L << 30));
        // Just over 1GB shows as gb
        assertEquals("01gb", ByteValue.humanReadable((1L << 30) + 1));
        assertEquals("10gb", ByteValue.humanReadable(10L * (1L << 30) + 1));
    }

    @Test
    public void testHumanReadableTerabytes() {
        // Note: uses strict > comparison, so exactly 1TB shows as gb
        assertEquals("1024gb", ByteValue.humanReadable(1L << 40));
        // Just over 1TB shows as tb
        assertEquals("01tb", ByteValue.humanReadable((1L << 40) + 1));
        assertEquals("10tb", ByteValue.humanReadable(10L * (1L << 40) + 1));
    }

    @Test
    public void testHumanReadablePetabytes() {
        // Note: uses strict > comparison, so exactly 1PB shows as tb
        assertEquals("1024tb", ByteValue.humanReadable(1L << 50));
        // Just over 1PB shows as pb
        assertEquals("01pb", ByteValue.humanReadable((1L << 50) + 1));
        assertEquals("10pb", ByteValue.humanReadable(10L * (1L << 50) + 1));
    }

    @Test
    public void testHumanReadableChoosesAppropriateUnit() {
        // Just over 1KB should show as kb
        assertEquals("01kb", ByteValue.humanReadable((1L << 10) + 1));
        // Just over 1MB should show as mb
        assertEquals("01mb", ByteValue.humanReadable((1L << 20) + 1));
        // Just over 1GB should show as gb
        assertEquals("01gb", ByteValue.humanReadable((1L << 30) + 1));
    }
}

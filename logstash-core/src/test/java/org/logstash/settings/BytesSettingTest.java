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

package org.logstash.settings;

import org.junit.Test;
import org.logstash.RubyTestBase;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertThrows;
import static org.junit.Assert.assertTrue;

public class BytesSettingTest extends RubyTestBase {

    @Test
    public void testStringDefaultValueInBytes() {
        BytesSetting setting = new BytesSetting("test.bytes", "100b");
        assertEquals(100L, setting.value());
    }

    @Test
    public void testStringDefaultValueInKilobytes() {
        BytesSetting setting = new BytesSetting("test.bytes", "64kb");
        assertEquals(64L * 1024, setting.value());
    }

    @Test
    public void testStringDefaultValueInMegabytes() {
        BytesSetting setting = new BytesSetting("test.bytes", "8mb");
        assertEquals(8L * 1024 * 1024, setting.value());
    }

    @Test
    public void testStringDefaultValueInGigabytes() {
        BytesSetting setting = new BytesSetting("test.bytes", "1gb");
        assertEquals(1L * 1024 * 1024 * 1024, setting.value());
    }

    @Test
    public void testNumericDefaultValue() {
        BytesSetting setting = new BytesSetting("test.bytes", 1024L);
        assertEquals(1024L, setting.value());
    }

    @Test
    public void testSetWithStringValue() {
        BytesSetting setting = new BytesSetting("test.bytes", "1mb");
        setting.set("64mb");
        assertEquals(64L * 1024 * 1024, setting.value());
    }

    @Test
    public void testSetWithNumericValue() {
        BytesSetting setting = new BytesSetting("test.bytes", "1mb");
        setting.set(2048L);
        assertEquals(2048L, setting.value());
    }

    @Test
    public void testLargeValueExceedingIntegerMax() {
        // 2^31 bytes (2 GB), which exceeds Integer.MAX_VALUE
        long largeValue = 1L << 31;
        BytesSetting setting = new BytesSetting("test.bytes", "2gb");
        setting.set(largeValue);
        assertEquals(largeValue, setting.value());
    }

    @Test
    public void testCoerceNullThrowsException() {
        BytesSetting setting = new BytesSetting("test.bytes", "1mb");
        assertThrows(IllegalArgumentException.class, () -> setting.set(null));
    }

    @Test
    public void testCoerceInvalidTypeThrowsException() {
        BytesSetting setting = new BytesSetting("test.bytes", "1mb");
        assertThrows(IllegalArgumentException.class, () -> setting.set(new Object()));
    }

    @Test
    public void testValidationRejectsNegativeValue() {
        BytesSetting setting = new BytesSetting("test.bytes", "1mb", false);
        assertThrows(IllegalArgumentException.class, () -> {
            setting.set(-100L);
        });
    }

    @Test
    public void testZeroValueIsValid() {
        BytesSetting setting = new BytesSetting("test.bytes", "0b");
        assertEquals(0L, setting.value());
    }

    @Test
    public void testCaseInsensitiveUnits() {
        BytesSetting setting1 = new BytesSetting("test.bytes", "64MB");
        BytesSetting setting2 = new BytesSetting("test.bytes", "64mb");
        assertEquals(setting1.value(), setting2.value());
    }
}

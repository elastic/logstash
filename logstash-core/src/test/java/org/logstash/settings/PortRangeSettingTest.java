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

import org.jruby.RubyFixnum;
import org.jruby.RubyRange;
import org.jruby.runtime.ThreadContext;
import org.junit.Test;
import org.logstash.RubyUtil;

import static org.junit.Assert.*;

// Porting to Java of logstash-core/spec/logstash/settings/port_range_spec.rb
public class PortRangeSettingTest {

    private static void assertThrowsError(String expectedErrorMessage, Runnable action) {
        try {
            action.run();
            fail("An error must be thrown");
        } catch (IllegalArgumentException ex) {
            assertTrue(ex.getMessage().contains(expectedErrorMessage));
        }
    }

    @Test
    public void givenPortRangeCreatedWithSingleIntegerValue_thenCoercesTheValueToRange() {
        PortRangeSetting sut = new PortRangeSetting("test", 9_000);
        assertEquals(new Range<>(9_000, 9_000), sut.value());
    }

    @Test
    public void givenPortRangeCreatedWithSingleIntegerValue_thenCanUpdateTheRange() {
        PortRangeSetting sut = new PortRangeSetting("test", 9_000);
        sut.set(10_000);
        assertEquals(new Range<>(10_000, 10_000), sut.value());
    }

    @Test
    public void givenPortRangeCreatedWithStringValue_thenCoercesTheValueToRange() {
        PortRangeSetting sut = new PortRangeSetting("test", "9000-10000");
        assertEquals(new Range<>(9_000, 10_000), sut.value());
        sut = new PortRangeSetting("test", " 9000-10000 ");
        assertEquals(new Range<>(9_000, 10_000), sut.value());
    }

    @Test
    public void givenPortRangeCreatedWithStringValue_whenUpperPortIsOutOfRange_thenThrowsAnError() {
        assertThrowsError("valid options are within the range of 1-65535",
                () -> new PortRangeSetting("test", "9000-95000")
        );
    }

    @Test
    public void givenPortRangeCreatedWithStringValue_thenCanUpdateTheRange() {
        PortRangeSetting sut = new PortRangeSetting("test", "9000-10000");
        sut.set("500-1000");
        assertEquals(new Range<>(500, 1000), sut.value());
    }

    @Test
    public void givenPortRangeCreatedWithGarbageString_thenThrowsAnError() {
        assertThrowsError("Could not coerce [fsdfnsdkjnfjs](type: class java.lang.String) into a port range",
                () -> new PortRangeSetting("test", "fsdfnsdkjnfjs")
        );
    }

    @Test
    public void givenPortRange_whenUpdatedWithGarbageString_thenThrowsAnError() {
        final PortRangeSetting sut = new PortRangeSetting("test", 10_000);
        assertThrowsError("Could not coerce [dsfnsdknfksdnfjksdnfjns](type: class java.lang.String) into a port range",
                () -> sut.set("dsfnsdknfksdnfjksdnfjns")
        );
    }

    @Test
    public void givenPortRangeCreatedWithUnknownType_thenThrowsAnError() {
        assertThrowsError("Could not coerce [0.1](type: class java.lang.Double) into a port range",
                () -> new PortRangeSetting("test", 0.1)
        );
    }

    @Test
    public void givenPortRange_whenUpdatedWithUnknownType_thenThrowsAnError() {
        final PortRangeSetting sut = new PortRangeSetting("test", 10_000);
        assertThrowsError("Could not coerce [0.1](type: class java.lang.Double) into a port range",
                () -> sut.set(0.1)
        );
    }

    @Test
    public void givenPortRangeCreatedWithRangeValue_thenCoercesTheValueToRange() {
        PortRangeSetting sut = new PortRangeSetting("test", new Range<>(9_000, 10_000));
        assertEquals(new Range<>(9_000, 10_000), sut.value());
    }

    @Test
    public void givenPortRangeCreatedWithRubyRangeValue_thenCoercesTheValueToRange() {
        ThreadContext ctx = RubyUtil.RUBY.getCurrentContext();
        RubyRange rubyRange = RubyRange.newExclusiveRange(ctx, new RubyFixnum(RubyUtil.RUBY, 9_000), new RubyFixnum(RubyUtil.RUBY, 10_000));
        PortRangeSetting sut = new PortRangeSetting("test", rubyRange);
        assertEquals(new Range<>(9_000, 10_000), sut.value());
    }

    @Test
    public void givenPortRangeCreatedWithRangeValue_thenCanUpdateTheRange() {
        PortRangeSetting sut = new PortRangeSetting("test", new Range<>(9_000, 10_000));
        sut.set(new Range<>(500, 1_000));
        assertEquals(new Range<>(500, 1_000), sut.value());
    }

    @Test
    public void givenPortRangeCreatedWithOutOfRangeUpperPort_thenThrowsAnError() {
        assertThrowsError("valid options are within the range of 1-65535",
                () -> new PortRangeSetting("test", new Range<>(9_000, 90_000))
        );
    }

    @Test
    public void givenPortRangeCreatedWithOutOfRangePort_thenThrowsAnError() {
        assertThrowsError("valid options are within the range of 1-65535",
                () -> new PortRangeSetting("test", new Range<>(-1_000, 1_000))
        );
    }
}
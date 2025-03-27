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

package org.logstash.common;

import org.hamcrest.Matchers;
import org.jruby.RubyArray;
import org.jruby.RubyString;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.junit.Before;
import org.junit.Test;
import org.logstash.RubyTestBase;
import org.logstash.RubyUtil;
import org.logstash.util.JavaVersion;

import javax.management.Attribute;
import javax.management.InstanceNotFoundException;
import javax.management.ReflectionException;
import java.lang.management.ManagementFactory;
import java.lang.management.OperatingSystemMXBean;
import java.util.List;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertThrows;
import static org.junit.Assume.assumeThat;
import static org.junit.Assume.assumeTrue;
import static org.logstash.RubyUtil.RUBY;

@SuppressWarnings("unchecked")
public final class BufferedTokenizerExtWithSizeLimitTest extends RubyTestBase {

    public static final int GB = 1024 * 1024 * 1024;
    private BufferedTokenizerExt sut;
    private ThreadContext context;

    @Before
    public void setUp() {
        initSUTWithSizeLimit(10);
    }

    private void initSUTWithSizeLimit(int sizeLimit) {
        sut = new BufferedTokenizerExt(RubyUtil.RUBY, RubyUtil.BUFFERED_TOKENIZER);
        context = RUBY.getCurrentContext();
        IRubyObject[] args = {RubyUtil.RUBY.newString("\n"), RubyUtil.RUBY.newFixnum(sizeLimit)};
        sut.init(context, args);
    }

    @Test
    public void givenTokenWithinSizeLimitWhenExtractedThenReturnTokens() {
        RubyArray<RubyString> tokens = (RubyArray<RubyString>) sut.extract(context, RubyUtil.RUBY.newString("foo\nbar\n"));

        assertEquals(List.of("foo", "bar"), tokens);
    }

    @Test
    public void givenTokenExceedingSizeLimitWhenExtractedThenThrowsAnError() {
        Exception thrownException = assertThrows(IllegalStateException.class, () -> {
            sut.extract(context, RubyUtil.RUBY.newString("this_is_longer_than_10\nkaboom"));
        });
        assertThat(thrownException.getMessage(), containsString("input buffer full"));
    }

    @Test
    public void givenExtractedThrownLimitErrorWhenFeedFreshDataThenReturnTokenStartingFromEndOfOffendingToken() {
        Exception thrownException = assertThrows(IllegalStateException.class, () -> {
            sut.extract(context, RubyUtil.RUBY.newString("this_is_longer_than_10\nkaboom"));
        });
        assertThat(thrownException.getMessage(), containsString("input buffer full"));

        RubyArray<RubyString> tokens = (RubyArray<RubyString>) sut.extract(context, RubyUtil.RUBY.newString("\nanother"));
        assertEquals("After buffer full error should resume from the end of line", List.of("kaboom"), tokens);
    }

    @Test
    public void givenExtractInvokedWithDifferentFramingAfterBufferFullErrorTWhenFeedFreshDataThenReturnTokenStartingFromEndOfOffendingToken() {
        sut.extract(context, RubyUtil.RUBY.newString("aaaa"));

        Exception thrownException = assertThrows(IllegalStateException.class, () -> {
            sut.extract(context, RubyUtil.RUBY.newString("aaaaaaa"));
        });
        assertThat(thrownException.getMessage(), containsString("input buffer full"));

        RubyArray<RubyString> tokens = (RubyArray<RubyString>) sut.extract(context, RubyUtil.RUBY.newString("aa\nbbbb\nccc"));
        assertEquals(List.of("bbbb"), tokens);
    }

    @Test
    public void giveMultipleSegmentsThatGeneratesMultipleBufferFullErrorsThenIsAbleToRecoverTokenization() {
        sut.extract(context, RubyUtil.RUBY.newString("aaaa"));

        //first buffer full on 13 "a" letters
        Exception thrownException = assertThrows(IllegalStateException.class, () -> {
            sut.extract(context, RubyUtil.RUBY.newString("aaaaaaa"));
        });
        assertThat(thrownException.getMessage(), containsString("input buffer full"));

        // second buffer full on 11 "b" letters
        Exception secondThrownException = assertThrows(IllegalStateException.class, () -> {
            sut.extract(context, RubyUtil.RUBY.newString("aa\nbbbbbbbbbbb\ncc"));
        });
        assertThat(secondThrownException.getMessage(), containsString("input buffer full"));

        // now should resemble processing on c and d
        RubyArray<RubyString> tokens = (RubyArray<RubyString>) sut.extract(context, RubyUtil.RUBY.newString("ccc\nddd\n"));
        assertEquals(List.of("ccccc", "ddd"), tokens);
    }

    @Test
    public void givenTooLongInputExtractDoesntOverflow() {
        // This test has proven to go OOM on JDK 11 and JDK 17, also if physical memory is 16GB.
        // JDK 21 successfully executes the test due to internal changes or efficiency of G1GC (the default GC).
        // Tested also others GC on JDK 11 without any success:
        // - ZGC
        // - Parallel GC
        // - CMS
        // remove this code when the minimal JDK version for Logstash is JDK 21 or greater.

        assumeThat("Expect at least JDK 21", JavaVersion.CURRENT, Matchers.greaterThanOrEqualTo(JavaVersion.JAVA_21));
        long expectedNeedHeapMemory = 10L * GB;
        // To understand the motivation of 10GB heap please read https://github.com/elastic/logstash/pull/17373#issuecomment-2750378212
        assumeTrue("Skip the test because VM hasn't enough physical memory", hasEnoughPhysicalMemory(expectedNeedHeapMemory));

        assertEquals("Xmx must equals to what's defined in the Gradle's javaTests task",
                expectedNeedHeapMemory, Runtime.getRuntime().maxMemory());

        // re-init the tokenizer with big sizeLimit
        initSUTWithSizeLimit((int) (2L * GB) - 3);
        // Integer.MAX_VALUE is 2 * GB
        RubyString bigFirstPiece = generateString("a", Integer.MAX_VALUE - 1024);
        sut.extract(context, bigFirstPiece);

        // add another small fragment to trigger int overflow
        // sizeLimit is (2^32-1)-3 first segment length is (2^32-1) - 1024 second is 1024 +2
        // so the combined length of first and second is > sizeLimit and should throw an exception
        // but because of overflow it's negative and happens to be < sizeLimit
        Exception thrownException = assertThrows(IllegalStateException.class, () -> {
            sut.extract(context, generateString("a", 1024 + 2));
        });
        assertThat(thrownException.getMessage(), containsString("input buffer full"));
    }

    private RubyString generateString(String fill, int size) {
        return RubyUtil.RUBY.newString(fill.repeat(size));
    }

    private boolean hasEnoughPhysicalMemory(long requiredPhysicalMemory) {
        long physicalMemory;
        try {
            physicalMemory = readPhysicalMemorySize();
        } catch (InstanceNotFoundException | ReflectionException e) {
            System.out.println("Can't read attribute JMX OS bean");
            return false;
        } catch (IllegalStateException e) {
            System.out.println(e.getMessage());
            return false;
        }
        System.out.println("Physical memory on the VM is: " + physicalMemory + " bytes");
        return physicalMemory > requiredPhysicalMemory;
    }

    private long readPhysicalMemorySize() throws ReflectionException, InstanceNotFoundException {
        OperatingSystemMXBean op = ManagementFactory.getOperatingSystemMXBean();

        List<Attribute> attributes = ManagementFactory.getPlatformMBeanServer()
                .getAttributes(op.getObjectName(), new String[]{"TotalPhysicalMemorySize"} ).asList();
        if (attributes.isEmpty()) {
            throw new IllegalStateException("Attribute TotalPhysicalMemorySize is not available from JMX OS bean");
        }
        Attribute a = attributes.get(0);
        return (long) (Long) a.getValue();
    }
}
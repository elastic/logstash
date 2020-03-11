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


package org.logstash.config.ir.compiler;

import co.elastic.logstash.api.Codec;
import co.elastic.logstash.api.Event;
import co.elastic.logstash.api.Metric;
import co.elastic.logstash.api.PluginConfigSpec;
import com.google.common.collect.ImmutableMap;
import org.jruby.RubyHash;
import org.junit.Before;
import org.junit.Test;
import org.logstash.plugins.ContextImpl;
import org.logstash.plugins.MetricTestCase;
import org.mockito.Mockito;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.ByteBuffer;
import java.util.Collection;
import java.util.Map;
import java.util.function.Consumer;

import static org.junit.Assert.assertEquals;

public class JavaCodecDelegatorTest extends MetricTestCase {
    private Codec codec;

    @Before
    public void setup() {
        this.codec = Mockito.mock(AbstractCodec.class);
        Mockito.when(this.codec.getId()).thenCallRealMethod();
        Mockito.when(this.codec.getName()).thenCallRealMethod();

        super.setup();
    }

    @Test
    public void plainCodecDelegatorInitializesCleanly() {
        constructCodecDelegator();
    }

    @Test
    public void plainCodecPluginPushesPluginNameToMetric() {
        constructCodecDelegator();
        final RubyHash metricStore = getMetricStore(new String[]{"codecs", "foo"});
        final String pluginName = getMetricStringValue(metricStore, "name");

        assertEquals(codec.getName(), pluginName);
    }

    @Test
    public void delegatesClone() {
        final JavaCodecDelegator codecDelegator = constructCodecDelegator();
        codecDelegator.cloneCodec();
        Mockito.verify(codec, Mockito.times(1)).cloneCodec();
    }

    @Test
    public void delegatesConfigSchema() {
        final JavaCodecDelegator codecDelegator = constructCodecDelegator();
        codecDelegator.configSchema();
        Mockito.verify(codec, Mockito.times(1)).configSchema();
    }

    @Test
    public void delegatesGetName() {
        Mockito.when(codec.getName()).thenReturn("MyLogstashPluginName");
        final JavaCodecDelegator codecDelegator = constructCodecDelegator();
        assertEquals("MyLogstashPluginName", codecDelegator.getName());
    }

    @Test
    public void delegatesGetId() {
        Mockito.when(codec.getId()).thenReturn("MyLogstashPluginId");
        final JavaCodecDelegator codecDelegator = constructCodecDelegator();
        assertEquals("MyLogstashPluginId", codecDelegator.getId());
    }

    @Test
    public void decodeDelegatesCall() {
        final Map<String, Object> ret = ImmutableMap.of("message", "abcdef");

        codec = Mockito.spy(new AbstractCodec() {
            @Override
            public void decode(final ByteBuffer buffer, final Consumer<Map<String, Object>> eventConsumer) {
                eventConsumer.accept(ret);
            }
        });

        final JavaCodecDelegator codecDelegator = constructCodecDelegator();

        final ByteBuffer buf = ByteBuffer.wrap(new byte[] {1, 2, 3});
        @SuppressWarnings("unchecked")
        final Consumer<Map<String, Object>> consumer = (Consumer<Map<String, Object>>) Mockito.mock(Consumer.class);

        codecDelegator.decode(buf, consumer);

        Mockito.verify(codec, Mockito.times(1)).decode(Mockito.eq(buf), Mockito.any());
        Mockito.verify(consumer, Mockito.times(1)).accept(ret);
    }

    @Test
    public void decodeIncrementsEventCount() {
        codec = new AbstractCodec() {
            @Override
            public void decode(final ByteBuffer buffer, final Consumer<Map<String, Object>> eventConsumer) {
                eventConsumer.accept(ImmutableMap.of("message", "abcdef"));
                eventConsumer.accept(ImmutableMap.of("message", "1234567"));
            }
        };

        final JavaCodecDelegator codecDelegator = constructCodecDelegator();

        codecDelegator.decode(ByteBuffer.wrap(new byte[] {1, 2, 3}), (e) -> {});

        assertEquals(1, getMetricLongValue("decode", "writes_in"));
        assertEquals(2, getMetricLongValue("decode", "out"));
    }

    @Test
    public void flushDelegatesCall() {
        final Map<String, Object> ret = ImmutableMap.of("message", "abcdef");

        codec = Mockito.spy(new AbstractCodec() {
            @Override
            public void flush(final ByteBuffer buffer, final Consumer<Map<String, Object>> eventConsumer) {
                eventConsumer.accept(ret);
            }
        });

        final JavaCodecDelegator codecDelegator = constructCodecDelegator();

        final ByteBuffer buf = ByteBuffer.wrap(new byte[] {1, 2, 3});
        @SuppressWarnings("unchecked")
        final Consumer<Map<String, Object>> consumer = (Consumer<Map<String, Object>>) Mockito.mock(Consumer.class);

        codecDelegator.flush(buf, consumer);

        Mockito.verify(codec, Mockito.times(1)).flush(Mockito.eq(buf), Mockito.any());
        Mockito.verify(consumer, Mockito.times(1)).accept(ret);
    }

    @Test
    public void flushIncrementsEventCount() {
        codec = new AbstractCodec() {
            @Override
            public void flush(final ByteBuffer buffer, final Consumer<Map<String, Object>> eventConsumer) {
                eventConsumer.accept(ImmutableMap.of("message", "abcdef"));
                eventConsumer.accept(ImmutableMap.of("message", "1234567"));
            }
        };

        final JavaCodecDelegator codecDelegator = constructCodecDelegator();

        codecDelegator.flush(ByteBuffer.wrap(new byte[] {1, 2, 3}), (e) -> {});

        assertEquals(1, getMetricLongValue("decode", "writes_in"));
        assertEquals(2, getMetricLongValue("decode", "out"));
    }

    @Test
    public void encodeDelegatesCall() throws IOException {
        codec = Mockito.spy(new AbstractCodec() {
            @Override
            public void encode(final Event event, final OutputStream out) {}
        });

        final JavaCodecDelegator codecDelegator = constructCodecDelegator();

        final Event e = new org.logstash.Event();
        final OutputStream out = new ByteArrayOutputStream();

        codecDelegator.encode(e, out);

        Mockito.verify(codec, Mockito.times(1)).encode(e, out);
    }

    @Test
    public void encodeIncrementsEventCount() throws IOException {
        codec = new AbstractCodec() {
            @Override
            public void encode(final Event event, final OutputStream out) {}
        };

        final JavaCodecDelegator codecDelegator = constructCodecDelegator();

        codecDelegator.encode(new org.logstash.Event(), new ByteArrayOutputStream());

        assertEquals(1, getMetricLongValue("encode", "writes_in"));
    }

    private RubyHash getMetricStore(final String type) {
        return getMetricStore(new String[]{"codecs", "foo", type});
    }

    private long getMetricLongValue(final String type, final String symbolName) {
        return getMetricLongValue(getMetricStore(type), symbolName);
    }

    private JavaCodecDelegator constructCodecDelegator() {
        return new JavaCodecDelegator(new ContextImpl(null, this.getInstance()), codec);
    }

    private abstract class AbstractCodec implements Codec {
        @Override
        public void decode(final ByteBuffer buffer, final Consumer<Map<String, Object>> eventConsumer) {
            throw new UnsupportedOperationException();
        }

        @Override
        public void flush(final ByteBuffer buffer, final Consumer<Map<String, Object>> eventConsumer) {
            throw new UnsupportedOperationException();
        }

        @Override
        public void encode(final Event event, final OutputStream out) throws IOException {
            throw new UnsupportedOperationException();
        }

        @Override
        public Codec cloneCodec() {
            throw new UnsupportedOperationException();
        }

        @Override
        public Collection<PluginConfigSpec<?>> configSchema() {
            throw new UnsupportedOperationException();
        }

        @Override
        public String getId() {
            return "foo";
        }

        @Override
        public String getName() {
            return "bar";
        }
    }
}

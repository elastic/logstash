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


package org.logstash.plugins.inputs;

import co.elastic.logstash.api.Codec;
import co.elastic.logstash.api.Configuration;
import co.elastic.logstash.api.Context;
import co.elastic.logstash.api.Input;
import co.elastic.logstash.api.LogstashPlugin;
import co.elastic.logstash.api.PluginConfigSpec;
import co.elastic.logstash.api.PluginHelper;
import org.apache.logging.log4j.Logger;

import java.io.FileDescriptor;
import java.io.FileInputStream;
import java.io.IOException;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.nio.ByteBuffer;
import java.nio.channels.AsynchronousCloseException;
import java.nio.channels.FileChannel;
import java.util.Collection;
import java.util.Collections;
import java.util.Map;
import java.util.concurrent.CountDownLatch;
import java.util.function.Consumer;

/**
 * Java implementation of the "stdin" input
 * */
@LogstashPlugin(name = "java_stdin")
public class Stdin implements Input, Consumer<Map<String, Object>> {

    private final Logger logger;

    public static final PluginConfigSpec<Codec> CODEC_CONFIG =
            PluginConfigSpec.codecSetting("codec", "java_line");

    private static final int BUFFER_SIZE = 64 * 1024;

    private String hostname;
    private Codec codec;
    private volatile boolean stopRequested = false;
    private final CountDownLatch isStopped = new CountDownLatch(1);
    private FileChannel input;
    private Consumer<Map<String, Object>> writer;
    private String id;

    /**
     * Required constructor.
     *
     * @param id            Plugin id
     * @param configuration Logstash Configuration
     * @param context       Logstash Context
     */
    public Stdin(final String id, final Configuration configuration, final Context context) {
        this(id, configuration, context, new FileInputStream(FileDescriptor.in).getChannel());
    }

    Stdin(final String id, final Configuration configuration, final Context context, FileChannel inputChannel) {
        logger = context.getLogger(this);
        this.id = id;
        try {
            hostname = InetAddress.getLocalHost().getHostName();
        } catch (UnknownHostException e) {
            hostname = "[unknownHost]";
        }
        codec = configuration.get(CODEC_CONFIG);
        if (codec == null) {
            throw new IllegalStateException("Unable to obtain codec");
        }
        input = inputChannel;
    }

    @Override
    public void start(Consumer<Map<String, Object>> writer) {
        this.writer = writer;
        final ByteBuffer buffer = ByteBuffer.allocateDirect(BUFFER_SIZE);
        try {
            while (!stopRequested && (input.read(buffer) > -1)) {
                buffer.flip();
                codec.decode(buffer, this);
                buffer.compact();
            }
        } catch (AsynchronousCloseException e2) {
            // do nothing -- this happens when stop is called while the read loop is blocked on input.read()
        } catch (IOException e) {
            stopRequested = true;
            logger.error("Stopping stdin after read error", e);
            throw new IllegalStateException(e);
        } finally {
            try {
                input.close();
            } catch (IOException e) {
                // do nothing
            }

            buffer.flip();
            codec.flush(buffer, this);
            isStopped.countDown();
        }
    }

    @Override
    public void accept(Map<String, Object> event) {
        event.putIfAbsent("hostname", hostname);
        writer.accept(event);
    }

    @Override
    public void stop() {
        stopRequested = true;
        try {
            input.close(); // interrupts any pending reads
        } catch (IOException e) {
            // do nothing
        }
    }

    @Override
    public void awaitStop() throws InterruptedException {
        isStopped.await();
    }

    @Override
    public Collection<PluginConfigSpec<?>> configSchema() {
        return PluginHelper.commonInputSettings(Collections.singletonList(CODEC_CONFIG));
    }

    @Override
    public String getId() {
        return id;
    }
}

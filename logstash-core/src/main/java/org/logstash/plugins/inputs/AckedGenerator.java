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

import co.elastic.logstash.api.AcknowledgablePlugin;
import co.elastic.logstash.api.AcknowledgeBus;
import co.elastic.logstash.api.AcknowledgeTokenFactory;
import co.elastic.logstash.api.Configuration;
import co.elastic.logstash.api.Context;
import co.elastic.logstash.api.LogstashPlugin;
import co.elastic.logstash.api.PluginConfigSpec;

import java.util.Collection;
import java.util.Map;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.atomic.AtomicLong;
import java.util.function.Consumer;

import org.apache.logging.log4j.Logger;
import org.joda.time.DateTime;

@LogstashPlugin(name = "java_acked_generator")
public class AckedGenerator extends Generator implements AcknowledgablePlugin {

    private final Logger logger;
    private final AcknowledgeBus acknowledgeBus;
    private final AcknowledgeTokenFactory acknowledgeTokenFactory;
    private final AtomicLong tokenCount;
    private final AtomicLong awaitCount;
    private final CountDownLatch countDownLatch;
    private boolean isStopping;

    /**
     * Required constructor.
     *
     * @param id            Plugin id
     * @param configuration Logstash Configuration
     * @param context       Logstash Context
     */
    public AckedGenerator(final String id, final Configuration configuration, final Context context) {
        super(id, configuration, context);
        this.logger = context.getLogger(this);
        this.acknowledgeBus = context.getAcknowledgeBus();
        this.tokenCount = new AtomicLong();
        this.awaitCount = new AtomicLong();
        this.countDownLatch = new CountDownLatch(1);
        this.isStopping = false;
        if (this.acknowledgeBus == null
                || (this.acknowledgeTokenFactory = this.acknowledgeBus.registerPlugin(this)) == null) {
            throw new RuntimeException("Unable to register plugin on acknowledgeBus");
        }
    }

    @Override
    public void start(Consumer<Map<String, Object>> writer) {
        Consumer<Map<String, Object>> wrappedWriter = (map) -> {
            String token = Long.toString(this.tokenCount.getAndIncrement());
            this.awaitCount.incrementAndGet();
            map.put("@acknowledge_token",
                    acknowledgeTokenFactory.generateToken(token));
            logger.info("[{}] Pushing generated event number: {}", DateTime.now(), token);
            writer.accept(map);
        };
        super.start(wrappedWriter);
    }

    @Override
    public void stop() {
        super.stop();
        this.isStopping = true;
    }

    @Override
    public void awaitStop() throws InterruptedException {
        super.awaitStop();
        if (this.awaitCount.get() > 0) {
            logger.info("Awaiting {} acknowledges before stopping", this.awaitCount.get());
            this.countDownLatch.await();
        }
    }

    @Override
    public Collection<PluginConfigSpec<?>> configSchema() {
        return super.configSchema();
    }

    @Override
    public String getId() {
        return super.getId();
    }

    @Override
    public boolean acknowledge(String acknowledgeId) {
        logger.info("Acknowledged generated event number: {}", acknowledgeId);
        long count = this.awaitCount.decrementAndGet();
        logger.info("Awaiting {} acknowledges", count);
        if (this.isStopping && count == 0){
            this.countDownLatch.countDown();
        }
        return true;
    }

    @Override
    public boolean notifyCloned(String acknowledgeId) {
        logger.info("Generated event number: {} crossed pipeline boundries/was cloned", acknowledgeId);
        this.awaitCount.incrementAndGet();
        return false;
    }
}

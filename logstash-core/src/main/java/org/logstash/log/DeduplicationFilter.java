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

package org.logstash.log;

import com.google.common.hash.BloomFilter;
import com.google.common.hash.Funnels;
import org.apache.logging.log4j.core.Appender;
import org.apache.logging.log4j.core.Core;
import org.apache.logging.log4j.core.LogEvent;
import org.apache.logging.log4j.core.config.plugins.Plugin;
import org.apache.logging.log4j.core.config.plugins.PluginAttribute;
import org.apache.logging.log4j.core.config.plugins.PluginFactory;
import org.apache.logging.log4j.core.filter.AbstractFilter;

import java.nio.charset.StandardCharsets;

/**
 * Log4j2 filter that suppresses repeated log lines using a Guava {@link BloomFilter}.
 * <p>
 * Deduplication key is {@code level + formattedMessage}. The first occurrence of a key
 * yields {@link Result#NEUTRAL}; subsequent occurrences yield {@link Result#DENY}.
 * </p>
 * <p>
 * Example {@code log4j2.properties} wiring on an appender:
 * </p>
 * <pre>
 * appender.rolling.filter.dedup.type = DeduplicationFilter
 * appender.rolling.filter.dedup.falsePositiveProbability = 0.01
 * </pre>
 */
@Plugin(name = "DeduplicationFilter", category = Core.CATEGORY_NAME, elementType = Appender.ELEMENT_TYPE, printObject = true)
public final class DeduplicationFilter extends AbstractFilter {

    static final double DEFAULT_FALSE_POSITIVE_PROBABILITY = 0.01;
    private static final int DEFAULT_EXPECTED_INSERTIONS = 1_000_000;

    private final BloomFilter<CharSequence> seenKeys;

    @PluginFactory
    public static DeduplicationFilter createFilter(
            @PluginAttribute(value = "falsePositiveProbability", defaultDouble = DEFAULT_FALSE_POSITIVE_PROBABILITY)
            final double falsePositiveProbability) {
        return new DeduplicationFilter(resolveFalsePositiveProbability(falsePositiveProbability));
    }

    private DeduplicationFilter(final double falsePositiveProbability) {
        seenKeys = BloomFilter.create(
                Funnels.stringFunnel(StandardCharsets.UTF_8),
                DEFAULT_EXPECTED_INSERTIONS,
                falsePositiveProbability
        );
    }

    static double resolveFalsePositiveProbability(final double falsePositiveProbability) {
        if (falsePositiveProbability > 0.0 && falsePositiveProbability < 1.0) {
            return falsePositiveProbability;
        }
        return DEFAULT_FALSE_POSITIVE_PROBABILITY;
    }

    @Override
    public Result filter(final LogEvent event) {
        final CharSequence key = dedupKey(event);
        synchronized (seenKeys) {
            if (seenKeys.mightContain(key)) {
                return Result.DENY;
            }
            seenKeys.put(key);
            return Result.NEUTRAL;
        }
    }

    private static CharSequence dedupKey(final LogEvent event) {
        return event.getLevel().name() + '\0' + event.getMessage().getFormattedMessage();
    }
}

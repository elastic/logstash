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


import org.apache.logging.log4j.spi.LoggerContext;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.runners.MockitoJUnitRunner;

import java.net.URI;


import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit test for {@link LogstashLoggerContextFactory}
 */
@RunWith(MockitoJUnitRunner.class)
public class LogstashLoggerContextFactoryTest {

    @Mock
    private LoggerContext preEstablishedContext;

    private LogstashLoggerContextFactory contextFactory;

    @Before
    public void setup() {
        contextFactory = new LogstashLoggerContextFactory(preEstablishedContext);
    }

    @Test
    public void testGetContextAlwaysReturnsTheSameObject() {
        assertThat(contextFactory.getContext("", ClassLoader.getSystemClassLoader(), null, false))
                .isEqualTo(contextFactory.getContext("someRandomValue", null, null, false))
                .isEqualTo(contextFactory.getContext("someOtherRandomValue", ClassLoader.getSystemClassLoader(), null, false, URI.create("foo"), "name"));
    }
}

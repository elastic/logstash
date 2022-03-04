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


package org.logstash.secret.store;

import org.junit.Before;
import org.junit.Test;

import java.util.HashSet;
import java.util.Set;
import java.util.UUID;
import java.util.stream.IntStream;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for {@link SecureConfig}
 */
@SuppressWarnings({"rawtypes", "unchecked"})
public class SecureConfigTest {

    private SecureConfig secureConfig;

    @Before
    public void _setup() {
        secureConfig = new SecureConfig();
    }

    @Test
    public void test() throws Exception {
        Set<String> expected = new HashSet(100);
        IntStream.range(0, 100).forEach(i -> expected.add(UUID.randomUUID().toString()));
        expected.forEach(s -> secureConfig.add(s, s.toCharArray()));
        expected.forEach(s -> assertThat(secureConfig.getPlainText(s)).isEqualTo(s.toCharArray()));
        expected.forEach(s -> assertThat(secureConfig.has(s)));
        SecureConfig clone = secureConfig.clone();
        expected.forEach(s -> assertThat(clone.getPlainText(s)).isEqualTo(s.toCharArray()));
        expected.forEach(s -> assertThat(clone.has(s)));
        secureConfig.clearValues();
        //manually reset cleared flag to allow the assertions
        secureConfig.cleared = false;
        expected.forEach(s -> assertThat(secureConfig.getPlainText(s)).containsOnly('\0'));
        //clone is not zero'ed
        expected.forEach(s -> assertThat(clone.getPlainText(s)).isEqualTo(s.toCharArray()));
    }

    @Test(expected = IllegalStateException.class)
    public void testClearedAdd() {
        secureConfig.clearValues();
        secureConfig.add("foo", "bar".toCharArray());
    }

    @Test(expected = IllegalStateException.class)
    public void testClearedClone() {
        secureConfig.clearValues();
        secureConfig.clone();
    }

    @Test(expected = IllegalStateException.class)
    public void testClearedGet() {
        secureConfig.clearValues();
        secureConfig.getPlainText("foo");
    }
}
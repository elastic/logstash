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


package org.logstash.secret;


import org.junit.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for {@link SecretIdentifier}
 */
public class SecretIdentifierTest {

    /**
     * Example usage
     */
    @Test
    public void testBasic() {
        SecretIdentifier id = new SecretIdentifier("foo");
        assertThat(id.toExternalForm()).isEqualTo("urn:logstash:secret:v1:foo");
        assertThat(id.getKey()).isEqualTo("foo");
    }

    /**
     * identifiers are case insensitive
     */
    @Test
    public void testCase() {
        SecretIdentifier id = new SecretIdentifier("FOO");
        assertThat(id.toExternalForm()).isEqualTo("urn:logstash:secret:v1:foo");
        SecretIdentifier id2 = new SecretIdentifier("foo");
        assertThat(id).isEqualTo(id2);
        assertThat(id.getKey()).isEqualTo(id2.getKey());
        assertThat(id.toExternalForm()).isEqualTo(id.toExternalForm()).isEqualTo(id.toString()).isEqualTo(id2.toString());
    }

    /**
     * Colon in the key don't cause issues with parsing the colon separated URN
     */
    @Test
    public void testColon() {
        SecretIdentifier id = new SecretIdentifier("foo:bar");
        assertThat(id.toExternalForm()).isEqualTo("urn:logstash:secret:v1:foo:bar");
        assertThat(id.getKey()).isEqualTo("foo:bar");
    }

    @Test(expected = IllegalArgumentException.class)
    public void testEmptyKey() {
        new SecretIdentifier("");
    }

    /**
     * valid urns should be able to be constructed from the urn
     */
    @Test
    public void testFromExternal() {
        assertThat(SecretIdentifier.fromExternalForm("urn:logstash:secret:v1:foo")).isEqualTo(new SecretIdentifier("foo"));
        assertThat(SecretIdentifier.fromExternalForm("urn:logstash:secret:v1:foo:bar")).isEqualTo(new SecretIdentifier("foo:bar"));
    }

    @Test(expected = IllegalArgumentException.class)
    public void testFromExternalInvalid() {
        SecretIdentifier.fromExternalForm("urn:logstash:secret:invalid:foo");
    }

    @Test(expected = IllegalArgumentException.class)
    public void testNullKey() {
        new SecretIdentifier(null);
    }

}
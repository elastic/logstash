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

package org.logstash.util;

import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.ExpectedException;

import org.logstash.RubyTestBase;

import static org.junit.Assert.*;

public class CloudSettingIdTest extends RubyTestBase {

    private String input = "foobar:dXMtZWFzdC0xLmF3cy5mb3VuZC5pbyRub3RhcmVhbCRpZGVudGlmaWVy";
    private CloudSettingId sut;

    @Rule
    public ExpectedException exceptionRule = ExpectedException.none();

    @Before
    public void setUp() {
        sut = new CloudSettingId(input);
    }

    // when given unacceptable input
    @Test
    public void testNullInputDoenstThrowAnException() {
        new CloudSettingId(null);
    }

    @Test
    public void testNullInputMakesAllGettersReturnNull() {
        sut = new CloudSettingId(null);
        assertNull(sut.getOriginal());
        assertNull(sut.getDecoded());
        assertNull(sut.getLabel());
        assertNull(sut.getElasticsearchHost());
        assertNull(sut.getKibanaHost());
        assertNull(sut.getElasticsearchScheme());
        assertNull(sut.getKibanaScheme());
    }

    @Test
    public void testThrowExceptionWhenMalformedValueIsGiven() {
        String[] raw = new String[] {"first", "second"};
        String encoded = CloudSettingId.cloudIdEncode(raw);
        exceptionRule.expect(org.jruby.exceptions.ArgumentError.class);
        exceptionRule.expectMessage("Cloud Id, after decoding, is invalid. Format: '<segment1>$<segment2>$<segment3>'. Received: \"" + String.join("$", raw) + "\".");

        new CloudSettingId(encoded);
    }

    @Test
    public void testThrowExceptionWhenAtLeatOneSegmentIsEmpty() {
        String[] raw = new String[] {"first", "", "third"};
        String encoded = CloudSettingId.cloudIdEncode(raw);
        exceptionRule.expect(org.jruby.exceptions.ArgumentError.class);
        exceptionRule.expectMessage("Cloud Id, after decoding, is invalid. Format: '<segment1>$<segment2>$<segment3>'. Received: \"" + String.join("$", raw) + "\".");

        new CloudSettingId(encoded);
    }

    @Test
    public void testThrowExceptionWhenElasticSegmentSegmentIsUndefined() {
        String[] raw = new String[] {"us-east-1.aws.found.io", "undefined", "my-kibana"};
        String encoded = CloudSettingId.cloudIdEncode(raw);
        exceptionRule.expect(org.jruby.exceptions.ArgumentError.class);
        exceptionRule.expectMessage("Cloud Id, after decoding, elasticsearch segment is 'undefined', literally.");

        new CloudSettingId(encoded);
    }

    @Test
    public void testThrowExceptionWhenKibanaSegmentSegmentIsUndefined() {
        String[] raw = new String[] {"us-east-1.aws.found.io", "my-elastic-cluster", "undefined"};
        String encoded = CloudSettingId.cloudIdEncode(raw);
        exceptionRule.expect(org.jruby.exceptions.ArgumentError.class);
        exceptionRule.expectMessage("Cloud Id, after decoding, the kibana segment is 'undefined', literally. You may need to enable Kibana in the Cloud UI.");

        new CloudSettingId(encoded);
    }

    // without a label
    @Test
    public void testDecodingWithoutLabelSegment() {
        sut = new CloudSettingId("dXMtZWFzdC0xLmF3cy5mb3VuZC5pbyRub3RhcmVhbCRpZGVudGlmaWVy");

        assertEquals("#label is empty", "", sut.getLabel());
        assertEquals("#decode is set", "us-east-1.aws.found.io$notareal$identifier", sut.getDecoded());
    }

    // when given acceptable input, the accessors:
    @Test
    public void testAccessorsWithAcceptableInput() {
        assertEquals("#original has a value", input, sut.getOriginal());
        assertEquals("#decoded has a value", "us-east-1.aws.found.io$notareal$identifier", sut.getDecoded());
        assertEquals("#label has a value", "foobar", sut.getLabel());
        assertEquals("#elasticsearch_host has a value", "notareal.us-east-1.aws.found.io:443", sut.getElasticsearchHost());
        assertEquals("#elasticsearch_scheme has a value", "https", sut.getElasticsearchScheme());
        assertEquals("#kibana_host has a value", "identifier.us-east-1.aws.found.io:443", sut.getKibanaHost());
        assertEquals("#kibana_scheme has a value", "https", sut.getKibanaScheme());
        assertEquals("#to_s has a value of #decoded", sut.toString(), sut.getDecoded());
    }

    @Test
    public void testWhenCloudIdContainsPortDescriptionForESAndKibana() {
        sut = new CloudSettingId("different-es-kb-port:dXMtY2VudHJhbDEuZ2NwLmNsb3VkLmVzLmlvJGFjMzFlYmI5MDI0MTc3MzE1NzA0M2MzNGZkMjZmZDQ2OjkyNDMkYTRjMDYyMzBlNDhjOGZjZTdiZTg4YTA3NGEzYmIzZTA6OTI0NA==");

        assertEquals("decodes the elasticsearch port corretly", "ac31ebb90241773157043c34fd26fd46.us-central1.gcp.cloud.es.io:9243", sut.getElasticsearchHost());
        assertEquals("decodes the kibana port corretly", "a4c06230e48c8fce7be88a074a3bb3e0.us-central1.gcp.cloud.es.io:9244", sut.getKibanaHost());
    }

    @Test
    public void testWhenCloudIdContainsCloudPort() {
        sut = new CloudSettingId("custom-port:dXMtY2VudHJhbDEuZ2NwLmNsb3VkLmVzLmlvOjkyNDMkYWMzMWViYjkwMjQxNzczMTU3MDQzYzM0ZmQyNmZkNDYkYTRjMDYyMzBlNDhjOGZjZTdiZTg4YTA3NGEzYmIzZTA=");

        assertEquals("decodes the elasticsearch port corretly", "ac31ebb90241773157043c34fd26fd46.us-central1.gcp.cloud.es.io:9243", sut.getElasticsearchHost());
        assertEquals("decodes the kibana port corretly", "a4c06230e48c8fce7be88a074a3bb3e0.us-central1.gcp.cloud.es.io:9243", sut.getKibanaHost());
    }

    @Test
    public void testWhenCloudIdOnlyDefinesKibanaPort() {
        sut = new CloudSettingId("only-kb-set:dXMtY2VudHJhbDEuZ2NwLmNsb3VkLmVzLmlvJGFjMzFlYmI5MDI0MTc3MzE1NzA0M2MzNGZkMjZmZDQ2JGE0YzA2MjMwZTQ4YzhmY2U3YmU4OGEwNzRhM2JiM2UwOjkyNDQ=");

        assertEquals("defaults the elasticsearch port to 443", "ac31ebb90241773157043c34fd26fd46.us-central1.gcp.cloud.es.io:443", sut.getElasticsearchHost());
        assertEquals("decodes the kibana port corretly", "a4c06230e48c8fce7be88a074a3bb3e0.us-central1.gcp.cloud.es.io:9244", sut.getKibanaHost());
    }

    @Test
    public void testWhenCloudIdDefinesCloudPortAndKibanaPort() {
        sut = new CloudSettingId("host-and-kb-set:dXMtY2VudHJhbDEuZ2NwLmNsb3VkLmVzLmlvOjkyNDMkYWMzMWViYjkwMjQxNzczMTU3MDQzYzM0ZmQyNmZkNDYkYTRjMDYyMzBlNDhjOGZjZTdiZTg4YTA3NGEzYmIzZTA6OTI0NA==");

        assertEquals("sets the elasticsearch port to cloud port", "ac31ebb90241773157043c34fd26fd46.us-central1.gcp.cloud.es.io:9243", sut.getElasticsearchHost());
        assertEquals("overrides cloud port with the kibana port", "a4c06230e48c8fce7be88a074a3bb3e0.us-central1.gcp.cloud.es.io:9244", sut.getKibanaHost());
    }

    @Test
    public void testWhenCloudIdDefinesExtraData() {
        sut = new CloudSettingId("extra-items:dXMtY2VudHJhbDEuZ2NwLmNsb3VkLmVzLmlvJGFjMzFlYmI5MDI0MTc3MzE1NzA0M2MzNGZkMjZmZDQ2JGE0YzA2MjMwZTQ4YzhmY2U3YmU4OGEwNzRhM2JiM2UwJGFub3RoZXJpZCRhbmRhbm90aGVy");

        assertEquals("captures the elasticsearch host", "ac31ebb90241773157043c34fd26fd46.us-central1.gcp.cloud.es.io:443", sut.getElasticsearchHost());
        assertEquals("captures the kibana host", "a4c06230e48c8fce7be88a074a3bb3e0.us-central1.gcp.cloud.es.io:443", sut.getKibanaHost());
        assertArrayEquals("captures the remaining identifiers", new String[] {"anotherid", "andanother"}, sut.getOtherIdentifiers());
    }

    // when given acceptable input (with empty kibana uuid), the accessors:
    @Test
    public void testGivenAcceptableInputEmptyKibanaUUID() {
        input = "a-test:ZWNlLmhvbWUubGFuJHRlc3Qk";
        sut = new CloudSettingId(input); // ece.home.lan$test$

        assertEquals("#original has a value", input, sut.getOriginal());
        assertEquals("#decoded has a value", "ece.home.lan$test$", sut.getDecoded());
        assertEquals("#label has a value", "a-test", sut.getLabel());
        assertEquals("#elasticsearch_host has a value", "test.ece.home.lan:443", sut.getElasticsearchHost());
        assertEquals("#elasticsearch_scheme has a value", "https", sut.getElasticsearchScheme());
        // NOTE: kibana part is not relevant -> this is how python/beats(go) code behaves
        assertEquals("#kibana_host has a value", ".ece.home.lan:443", sut.getKibanaHost());
        assertEquals("#kibana_scheme has a value", "https", sut.getKibanaScheme());
        assertEquals("#toString has a value of #decoded", sut.getDecoded(), sut.toString());
    }

    // a lengthy real-world input, the accessors:
    @Test
    public void testWithRealWorldInput() {
        //eastus2.azure.elastic-cloud.com:9243$40b343116cfa4ebcb76c11ee2329f92d$43d09252502c4189a376fd0cf2cd0848
        input = "ZWFzdHVzMi5henVyZS5lbGFzdGljLWNsb3VkLmNvbTo5MjQzJDQwYjM0MzExNmNmYTRlYmNiNzZjMTFlZTIzMjlmOTJkJDQzZDA5MjUyNTAyYzQxODlhMzc2ZmQwY2YyY2QwODQ4";
        sut = new CloudSettingId(input);

        assertEquals("#original has a value", input, sut.getOriginal());
        assertEquals("#decoded has a value", "eastus2.azure.elastic-cloud.com:9243$40b343116cfa4ebcb76c11ee2329f92d$43d09252502c4189a376fd0cf2cd0848", sut.getDecoded());
        assertEquals("#label has a value", "", sut.getLabel());
        assertEquals("#elasticsearch_host has a value", "40b343116cfa4ebcb76c11ee2329f92d.eastus2.azure.elastic-cloud.com:9243", sut.getElasticsearchHost());
        assertEquals("#kibana_host has a value", "43d09252502c4189a376fd0cf2cd0848.eastus2.azure.elastic-cloud.com:9243", sut.getKibanaHost());
        assertEquals("#toString has a value of #decoded", sut.getDecoded(), sut.toString());
    }
}

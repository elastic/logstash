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

import org.logstash.RubyUtil;

import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Base64;

/*
 * The constructor is expecting a 'cloud.id', a string in 2 variants.
 * 1 part example: 'dXMtZWFzdC0xLmF3cy5mb3VuZC5pbyRub3RhcmVhbCRpZGVudGlmaWVy'
 * 2 part example: 'foobar:dXMtZWFzdC0xLmF3cy5mb3VuZC5pbyRub3RhcmVhbCRpZGVudGlmaWVy'
 * The two part variant has a 'label' prepended with a colon separator. The label is not encoded.
 * The 1 part (or second section of the 2 part variant) is base64 encoded.
 * The original string before encoding has three segments separated by a dollar sign.
 * e.g. 'us-east-1.aws.found.io$notareal$identifier'
 * The first segment is the cloud base url, e.g. 'us-east-1.aws.found.io'
 * The second segment is the elasticsearch host identifier, e.g. 'notareal'
 * The third segment is the kibana host identifier, e.g. 'identifier'
 * The 'cloud.id' value decoded into the various fields.
 */
/**
 * Represents and decode an Elastic cloudid of an instance.
 * */
public class CloudSettingId {

    private static class HostAndPort {
        static final HostAndPort NO_HOST = new HostAndPort("", null);
        private final String host;
        private final String port;

        private HostAndPort(String host, String port) {
            this.host = host;
            this.port = port;
        }

        String portOrDefault(String defaultPort) {
            return port == null ? defaultPort : port;
        }

        static HostAndPort parseHostAndPort(String part, String guidanceMessageWhenHostEqualsUndefined) {
            final String[] hostParts = part.split(":");
            String host = hostParts[0];
            if ("undefined".equals(host)) {
                throw RubyUtil.RUBY.newArgumentError(guidanceMessageWhenHostEqualsUndefined);
            }
            String port = null;
            if (hostParts.length > 1) {
                port = hostParts[1];
            }
            return new HostAndPort(host, port);
        }
    }

    public static final String DOT_SEPARATOR = ".";
    public static final String CLOUD_PORT = "443";

    private String original;
    private String decoded;
    private String label;
    private String elasticsearchScheme;
    private String elasticsearchHost;
    private String elasticsearchPort;
    private String kibanaScheme;
    private String kibanaHost;
    private String kibanaPort;
    private String[] otherIdentifiers = new String[0];

    public CloudSettingId(String value) {
        if (value == null) {
            return;
        }
        original = value;
        final String[] parts = original.split(":");
        label = parts[0];
        String encoded = null;
        if (parts.length > 1) {
            encoded = parts[1];
        }
        if (encoded == null || encoded.isEmpty()) {
            try {
                decoded = new String(Base64.getUrlDecoder().decode(label), StandardCharsets.UTF_8);
            } catch (IllegalArgumentException iaex) {
                decoded = "";
            }
            label = "";
        } else {
            try {
                decoded = new String(Base64.getUrlDecoder().decode(encoded), StandardCharsets.UTF_8);
            } catch (IllegalArgumentException iaex) {
                decoded = "";
            }
        }
        long separatorCount = decoded.chars().filter(c -> c == '$').count();
        if (separatorCount < 2) {
            throw RubyUtil.RUBY.newArgumentError("Cloud Id, after decoding, is invalid. Format: '<segment1>$<segment2>$<segment3>'. Received: \"" + decoded + "\".");
        }
        final String[] segments = decoded.split("\\$");
        if (Arrays.stream(segments).anyMatch(String::isEmpty)) {
            throw RubyUtil.RUBY.newArgumentError("Cloud Id, after decoding, is invalid. Format: '<segment1>$<segment2>$<segment3>'. Received: \"" + decoded + "\".");
        }
        String cloudBase = segments[0];
        String cloudHost = DOT_SEPARATOR + cloudBase;
        final String[] hostParts = cloudHost.split(":");
        final HostAndPort cloud = new HostAndPort(hostParts[0], hostParts.length > 1 ? hostParts[1] : CLOUD_PORT);

        final HostAndPort elasticsearch = HostAndPort.parseHostAndPort(segments[1], "Cloud Id, after decoding, elasticsearch segment is 'undefined', literally.");
        elasticsearchPort = elasticsearch.portOrDefault(cloud.port);
        elasticsearchHost = elasticsearch.host + cloud.host + ":" + elasticsearchPort;
        elasticsearchScheme = "https";

        final HostAndPort kibana;
        if (segments.length > 2) {
            kibana = HostAndPort.parseHostAndPort(segments[2], "Cloud Id, after decoding, the kibana segment is 'undefined', literally. You may need to enable Kibana in the Cloud UI.");
        } else {
            // non-sense really to have '.my-host:443' but we're mirroring others
            kibana = HostAndPort.NO_HOST;
        }
        kibanaPort = kibana.portOrDefault(cloud.port);
        kibanaHost = kibana.host + cloud.host + ":" + kibanaPort;
        kibanaScheme = "https";

        if (segments.length > 3) {
            otherIdentifiers = Arrays.copyOfRange(segments, 3, segments.length);
        }
    }

    public String getOriginal() {
        return original;
    }

    public String getDecoded() {
        return decoded;
    }

    public String getLabel() {
        return label;
    }

    public String getElasticsearchScheme() {
        return elasticsearchScheme;
    }

    public String getElasticsearchHost() {
        return elasticsearchHost;
    }

    public String getElasticsearchPort() {
        return elasticsearchPort;
    }

    public String getKibanaScheme() {
        return kibanaScheme;
    }

    public String getKibanaHost() {
        return kibanaHost;
    }

    public String getKibanaPort() {
        return kibanaPort;
    }

    public String[] getOtherIdentifiers() {
        return otherIdentifiers;
    }

    @Override
    public String toString() {
        return decoded;
    }

    public static String cloudIdEncode(String... args) {
        final String joinedArgs = String.join("$", args);
        return Base64.getUrlEncoder().encodeToString(joinedArgs.getBytes());
    }
}

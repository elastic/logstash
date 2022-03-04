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

import java.nio.charset.StandardCharsets;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for {@link SecretStoreUtil}
 */
public class SecretStoreUtilTest {

    private String asciiString;

    @Before
    public void _setup() {
        asciiString = UUID.randomUUID().toString();
    }

    @Test
    public void testAsciiBytesToChar() {
        byte[] asciiBytes = asciiString.getBytes(StandardCharsets.US_ASCII);
        char[] asciiChars = SecretStoreUtil.asciiBytesToChar(asciiBytes);
        assertThat(asciiChars).isEqualTo(asciiString.toCharArray());
        assertThat(asciiBytes).containsOnly('\0');
    }

    @Test
    public void testAsciiCharToBytes() {
        char[] asciiChars = asciiString.toCharArray();
        byte[] asciiBytes = SecretStoreUtil.asciiCharToBytes(asciiChars);
        assertThat(asciiBytes).isEqualTo(asciiString.getBytes(StandardCharsets.US_ASCII));
        assertThat(asciiChars).contains('\0');
    }

    @Test
    public void testBase64EncodeBytes() {
        byte[] asciiBytes = asciiString.getBytes(StandardCharsets.US_ASCII);
        byte[] base64Bytes = SecretStoreUtil.base64Encode(asciiBytes);
        assertThat(asciiBytes).containsOnly('\0');
        asciiBytes = SecretStoreUtil.base64Decode(base64Bytes);
        assertThat(base64Bytes).containsOnly('\0');
        assertThat(asciiBytes).isEqualTo(asciiString.getBytes(StandardCharsets.US_ASCII));
    }

    @Test
    public void testBase64EncodeBytesToChars() {
        byte[] asciiBytes = asciiString.getBytes(StandardCharsets.US_ASCII);
        char[] base64Chars = SecretStoreUtil.base64EncodeToChars(asciiBytes);
        assertThat(asciiBytes).containsOnly('\0');
        asciiBytes = SecretStoreUtil.base64Decode(base64Chars);
        assertThat(base64Chars).containsOnly('\0');
        assertThat(asciiBytes).isEqualTo(asciiString.getBytes(StandardCharsets.US_ASCII));
    }

    @Test
    public void testBase64EncodeChars() {
        char[] asciiChars = asciiString.toCharArray();
        char[] base64Chars = SecretStoreUtil.base64Encode(asciiChars);
        assertThat(asciiChars).containsOnly('\0');
        byte[] asciiBytes = SecretStoreUtil.base64Decode(base64Chars);
        assertThat(base64Chars).containsOnly('\0');
        assertThat(asciiBytes).isEqualTo(asciiString.getBytes(StandardCharsets.US_ASCII));
    }

    @Test
    public void testClear() {
        byte[] asciiBytes = asciiString.getBytes(StandardCharsets.US_ASCII);
        char[] base64Chars = SecretStoreUtil.base64EncodeToChars(asciiBytes);
        SecretStoreUtil.clearChars(base64Chars);
        assertThat(base64Chars).containsOnly('\0');
    }

    @Test
    public void testObfuscate() {
        String original = UUID.randomUUID().toString();
        assertThat(SecretStoreUtil.deObfuscate(SecretStoreUtil.obfuscate(original.toCharArray()))).isEqualTo(original.toCharArray());
    }

}
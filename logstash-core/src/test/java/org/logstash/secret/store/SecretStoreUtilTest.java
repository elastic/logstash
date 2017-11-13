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
    public void setup(){
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
    public void testAsciiCharToBytes(){
        char[] asciiChars = asciiString.toCharArray();
        byte[] asciiBytes = SecretStoreUtil.asciiCharToBytes(asciiChars);
        assertThat(asciiBytes).isEqualTo(asciiString.getBytes(StandardCharsets.US_ASCII));
        assertThat(asciiChars).contains('\0');
    }

    @Test
    public void testBase64EncodeBytes(){
        byte[] asciiBytes = asciiString.getBytes(StandardCharsets.US_ASCII);
        byte[] base64Bytes = SecretStoreUtil.base64Encode(asciiBytes);
        assertThat(asciiBytes).containsOnly('\0');
        asciiBytes = SecretStoreUtil.base64Decode(base64Bytes);
        assertThat(base64Bytes).containsOnly('\0');
        assertThat(asciiBytes).isEqualTo(asciiString.getBytes(StandardCharsets.US_ASCII));
    }

    @Test
    public void testBase64EncodeChars(){
        char[] asciiChars = asciiString.toCharArray();
        char[] base64Chars = SecretStoreUtil.base64Encode(asciiChars);
        assertThat(asciiChars).containsOnly('\0');
        byte[] asciiBytes = SecretStoreUtil.base64Decode(base64Chars);
        assertThat(base64Chars).containsOnly('\0');
        assertThat(asciiBytes).isEqualTo(asciiString.getBytes(StandardCharsets.US_ASCII));
    }
}
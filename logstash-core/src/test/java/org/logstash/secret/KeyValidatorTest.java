package org.logstash.secret;

import org.junit.Test;
import java.util.Objects;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.Assert.assertThrows;

public class KeyValidatorTest {

    @Test(expected = Test.None.class) // no exception expected
    public void testValidKeys() {
        KeyValidator.validateKey("validKey", "key");
        KeyValidator.validateKey("test123", "key");
        KeyValidator.validateKey("under_score", "key");
        KeyValidator.validateKey("hyphen-key", "key");
        KeyValidator.validateKey("uri:standard", "key");
        KeyValidator.validateKey("key-with.extension", "key");
    }

    @Test
    public void validateKeyThrowsCorrectMessage() {
        KeyValidator.RESTRICTED_SYMBOLS.forEach(symbol -> {
            String key = "random" + symbol + "test";
            IllegalArgumentException exception = assertThrows(
                    IllegalArgumentException.class,
                    () -> KeyValidator.validateKey(key, "key")
            );
            final String verifyPart = Objects.equals(" ", symbol) ? "whitespace" : symbol;
            assertThat(exception.getMessage()).isEqualTo(String.format("key can not contain %s", verifyPart));
        });
    }
}

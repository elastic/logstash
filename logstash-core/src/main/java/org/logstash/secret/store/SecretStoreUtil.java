package org.logstash.secret.store;

import java.util.Arrays;
import java.util.Base64;

/**
 * Conversion utility between String, bytes, and chars. All methods attempt to keep sensitive data out of memory. Sensitive data should avoid using Java {@link String}'s.
 */
final public class SecretStoreUtil {

    /**
     * Private constructor. Utility class.
     */
    private SecretStoreUtil() {
    }

    /**
     * Converts bytes from ascii encoded text to a char[] and zero outs the original byte[]
     *
     * @param bytes the bytes from an ascii encoded text (note - no validation is done to ensure ascii encoding)
     * @return the corresponding char[]
     */
    public static char[] asciiBytesToChar(byte[] bytes) {
        char[] chars = new char[bytes.length];
        for (int i = 0; i < bytes.length; i++) {
            chars[i] = (char) bytes[i];
            bytes[i] = '\0';
        }
        return chars;
    }

    /**
     * Converts characters from ascii encoded text to a byte[] and zero outs the original char[]
     *
     * @param chars the chars from an ascii encoded text (note - no validation is done to ensure ascii encoding)
     * @return the corresponding byte[]
     */
    public static byte[] asciiCharToBytes(char[] chars) {
        byte[] bytes = new byte[chars.length];
        for (int i = 0; i < chars.length; i++) {
            bytes[i] = (byte) chars[i];
            chars[i] = '\0';
        }
        return bytes;
    }

    /**
     * Base64 encode the given byte[], then zero the original byte[]
     *
     * @param b the byte[] to base64 encode
     * @return the base64 encoded bytes
     */
    public static byte[] base64Encode(byte[] b) {
        byte[] bytes = Base64.getEncoder().encode(b);
        clearBytes(b);
        return bytes;
    }

    /**
     * Base64 encode the given char[], then zero out the original char[]
     *
     * @param chars the char[] to base64 encode
     * @return the char[] representation of the base64 encoding
     */
    public static char[] base64Encode(char[] chars) {
        return asciiBytesToChar(base64Encode(asciiCharToBytes(chars)));
    }

    /**
     * Decodes a Base64 encoded byte[], then zero out the original byte[]
     *
     * @param b the base64 bytes
     * @return the non-base64 encoded bytes
     */
    public static byte[] base64Decode(byte[] b) {
        byte[] bytes = Base64.getDecoder().decode(b);
        clearBytes(b);
        return bytes;
    }

    /**
     * Decodes a Base64 encoded char[], then zero out the original char[]
     *
     * @param chars the base64 chars
     * @return the non-base64 encoded chars
     */
    public static byte[] base64Decode(char[] chars) {
        return base64Decode(asciiCharToBytes(chars));
    }

    /**
     * Attempt to keep data out of the heap.
     *
     * @param bytes the bytes to zero out
     */
    public static void clearBytes(byte[] bytes) {
        Arrays.fill(bytes, (byte) '\0');
    }
}

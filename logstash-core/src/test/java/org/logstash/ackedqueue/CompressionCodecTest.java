package org.logstash.ackedqueue;

import com.github.luben.zstd.Zstd;
import org.apache.logging.log4j.Logger;
import org.junit.Test;
import org.mockito.Mockito;

import java.security.SecureRandom;
import java.util.Arrays;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.*;
import static org.junit.Assert.assertThrows;
import static org.mockito.Matchers.argThat;

public class CompressionCodecTest {
    static final ImmutableByteArrayBarrier RAW_BYTES = new ImmutableByteArrayBarrier((
            "this is a string of text with repeated substrings that is designed to be "+
            "able to be compressed into a string that is smaller than the original input "+
            "so that we can assert that the compression codecs compress strings to be "+
            "smaller than their uncompressed representations").getBytes());
    static final ImmutableByteArrayBarrier COMPRESSED_MINIMAL = new ImmutableByteArrayBarrier(compress(RAW_BYTES.bytes(), -1));
    static final ImmutableByteArrayBarrier COMPRESSED_DEFAULT = new ImmutableByteArrayBarrier(compress(RAW_BYTES.bytes(), 3));
    static final ImmutableByteArrayBarrier COMPRESSED_MAXIMUM = new ImmutableByteArrayBarrier(compress(RAW_BYTES.bytes(), 22));

    private final CompressionCodec codecDisabled = CompressionCodec.fromConfigValue("disabled").create();
    private final CompressionCodec codecNone = CompressionCodec.fromConfigValue("none").create();
    private final CompressionCodec codecSpeed = CompressionCodec.fromConfigValue("speed").create();
    private final CompressionCodec codecBalanced = CompressionCodec.fromConfigValue("balanced").create();
    private final CompressionCodec codecSize = CompressionCodec.fromConfigValue("size").create();

    @Test
    public void testDisabledCompressionCodecDecodes() throws Exception {
        final CompressionCodec compressionCodec = CompressionCodec.fromConfigValue("disabled").create();
        assertDecodesRaw(compressionCodec);

        // ensure true pass-through when compression is disabled, even if the payload looks like ZSTD
        assertThat(compressionCodec.decode(COMPRESSED_MINIMAL.bytes()), is(equalTo(COMPRESSED_MINIMAL.bytes())));
        assertThat(compressionCodec.decode(COMPRESSED_DEFAULT.bytes()), is(equalTo(COMPRESSED_DEFAULT.bytes())));
        assertThat(compressionCodec.decode(COMPRESSED_MAXIMUM.bytes()), is(equalTo(COMPRESSED_MAXIMUM.bytes())));
    }

    @Test
    public void testDisabledCompressionCodecEncodes() throws Exception {
        final CompressionCodec compressionCodec = CompressionCodec.fromConfigValue("disabled").create();
        // ensure true pass-through when compression is disabled
        assertThat(compressionCodec.encode(RAW_BYTES.bytes()), is(equalTo(RAW_BYTES.bytes())));
    }

    @Test
    public void testDisabledCompressionCodecLogging() throws Exception {
        final Logger mockLogger = Mockito.mock(Logger.class);
        CompressionCodec.fromConfigValue("disabled", mockLogger).create();
        Mockito.verify(mockLogger).warn(argThat(stringContainsInOrder("compression support", "disabled")));
    }

    @Test
    public void testNoneCompressionCodecDecodes() throws Exception {
        final CompressionCodec compressionCodec = CompressionCodec.fromConfigValue("none").create();
        assertDecodesRaw(compressionCodec);
        assertDecodesDeflateAnyLevel(compressionCodec);
        assertDecodesOutputOfAllKnownCompressionCodecs(compressionCodec);
    }

    @Test
    public void testNoneCompressionCodecEncodes() throws Exception {
        final CompressionCodec compressionCodec = CompressionCodec.fromConfigValue("none").create();
        assertThat(compressionCodec.encode(RAW_BYTES.bytes()), is(equalTo(RAW_BYTES.bytes())));
    }

    @Test
    public void testNoneCompressionCodecLogging() throws Exception {
        final Logger mockLogger = Mockito.mock(Logger.class);
        CompressionCodec.fromConfigValue("none", mockLogger).create();
        Mockito.verify(mockLogger).info(argThat(stringContainsInOrder("compression support", "enabled", "read-only")));
    }

    @Test
    public void testSpeedCompressionCodecDecodes() throws Exception {
        final CompressionCodec compressionCodec = CompressionCodec.fromConfigValue("speed").create();
        assertDecodesRaw(compressionCodec);
        assertDecodesDeflateAnyLevel(compressionCodec);
        assertDecodesOutputOfAllKnownCompressionCodecs(compressionCodec);
    }

    @Test
    public void testSpeedCompressionCodecEncodes() throws Exception {
        final CompressionCodec compressionCodec = CompressionCodec.fromConfigValue("speed").create();
        assertEncodesSmallerRoundTrip(compressionCodec);
    }

    @Test
    public void testSpeedCompressionCodecLogging() throws Exception {
        final Logger mockLogger = Mockito.mock(Logger.class);
        CompressionCodec.fromConfigValue("speed", mockLogger).create();
        Mockito.verify(mockLogger).info(argThat(stringContainsInOrder("compression support", "enabled", "speed")));
    }

    @Test
    public void testBalancedCompressionCodecDecodes() throws Exception {
        final CompressionCodec compressionCodec = CompressionCodec.fromConfigValue("balanced").create();
        assertDecodesRaw(compressionCodec);
        assertDecodesDeflateAnyLevel(compressionCodec);
        assertDecodesOutputOfAllKnownCompressionCodecs(compressionCodec);
    }

    @Test
    public void testBalancedCompressionCodecEncodes() throws Exception {
        final CompressionCodec compressionCodec = CompressionCodec.fromConfigValue("balanced").create();
        assertEncodesSmallerRoundTrip(compressionCodec);
    }

    @Test
    public void testBalancedCompressionCodecLogging() throws Exception {
        final Logger mockLogger = Mockito.mock(Logger.class);
        CompressionCodec.fromConfigValue("balanced", mockLogger).create();
        Mockito.verify(mockLogger).info(argThat(stringContainsInOrder("compression support", "enabled", "balanced")));
    }

    @Test
    public void testSizeCompressionCodecDecodes() throws Exception {
        final CompressionCodec compressionCodec = CompressionCodec.fromConfigValue("size").create();
        assertDecodesRaw(compressionCodec);
        assertDecodesDeflateAnyLevel(compressionCodec);
        assertDecodesOutputOfAllKnownCompressionCodecs(compressionCodec);
    }

    @Test
    public void testSizeCompressionCodecEncodes() throws Exception {
        final CompressionCodec compressionCodec = CompressionCodec.fromConfigValue("size").create();
        assertEncodesSmallerRoundTrip(compressionCodec);
    }

    @Test
    public void testSizeCompressionCodecLogging() throws Exception {
        final Logger mockLogger = Mockito.mock(Logger.class);
        CompressionCodec.fromConfigValue("size", mockLogger).create();
        Mockito.verify(mockLogger).info(argThat(stringContainsInOrder("compression support", "enabled", "size")));
    }

    @Test(timeout=1000)
    public void testCompressionCodecDecodeTailTruncated() throws Exception {
        final byte[] truncatedInput = copyWithTruncatedTail(COMPRESSED_DEFAULT.bytes(), 32);

        final RuntimeException thrownException = assertThrows(RuntimeException.class, () -> codecNone.decode(truncatedInput));
        assertThat(thrownException.getMessage(), containsString("Exception while decoding"));
        final Throwable rootCause = extractRootCause(thrownException);
        assertThat(rootCause.getMessage(), containsString("Data corruption detected"));
    }

    byte[] copyWithTruncatedTail(final byte[] input, final int tailSize) {
        int startIndex = (input.length < tailSize) ? 0 : input.length - tailSize;

        final byte[] result = Arrays.copyOf(input, input.length);
        Arrays.fill(result, startIndex, result.length, (byte) 0);

        return result;
    }

    @Test(timeout=1000)
    public void testCompressionCodecDecodeTailScrambled() throws Exception {
        final byte[] scrambledInput = copyWithScrambledTail(COMPRESSED_DEFAULT.bytes(), 32);

        final RuntimeException thrownException = assertThrows(RuntimeException.class, () -> codecNone.decode(scrambledInput));
        assertThat(thrownException.getMessage(), containsString("Exception while decoding"));
        final Throwable rootCause = extractRootCause(thrownException);
        assertThat(rootCause.getMessage(), anyOf(containsString("Data corruption detected"), containsString("Destination buffer is too small")));
    }

    byte[] copyWithScrambledTail(final byte[] input, final int tailSize) {
        final SecureRandom secureRandom = new SecureRandom();
        int startIndex = (input.length < tailSize) ? 0 : input.length - tailSize;

        byte[] randomBytes = new byte[input.length - startIndex];
        secureRandom.nextBytes(randomBytes);

        final byte[] result = Arrays.copyOf(input, input.length);
        System.arraycopy(randomBytes, 0, result, startIndex, randomBytes.length);

        return result;
    }

    @Test(timeout=1000)
    public void testCompressionDecodeTailNullPadded() throws Exception {
        final byte[] nullPaddedInput = copyWithNullPaddedTail(COMPRESSED_DEFAULT.bytes(), 32);

        final RuntimeException thrownException = assertThrows(RuntimeException.class, () -> codecNone.decode(nullPaddedInput));
        assertThat(thrownException.getMessage(), containsString("Exception while decoding"));
        final Throwable rootCause = extractRootCause(thrownException);
        assertThat(rootCause.getMessage(), anyOf(containsString("Unknown frame descriptor"), containsString("Data corruption detected")));
    }

    byte[] copyWithNullPaddedTail(final byte[] input, final int tailSize) {
        return Arrays.copyOf(input, Math.addExact(input.length, tailSize));
    }

    Throwable extractRootCause(final Throwable throwable) {
        Throwable current;
        Throwable cause = throwable;
        do {
            current = cause;
            cause = current.getCause();
        } while (cause != null && cause != current);
        return current;
    }

    void assertDecodesRaw(final CompressionCodec codec) {
        assertThat(codec.decode(RAW_BYTES.bytes()), is(equalTo(RAW_BYTES.bytes())));
    }

    void assertDecodesDeflateAnyLevel(final CompressionCodec codec) {
        // zstd levels range from -7 to 22.
        for (int level = -7; level < 22; level++) {
            final byte[] compressed = compress(RAW_BYTES.bytes(), level);
            assertThat(String.format("zstd level %s (%s bytes)", level, compressed.length), codec.decode(compressed), is(equalTo(RAW_BYTES.bytes())));
        }
    }

    void assertDecodesOutputOfAllKnownCompressionCodecs(final CompressionCodec codec) {
        assertThat(codec.decode(codecDisabled.encode(RAW_BYTES.bytes())), is(equalTo(RAW_BYTES.bytes())));
        assertThat(codec.decode(codecNone.encode(RAW_BYTES.bytes())), is(equalTo(RAW_BYTES.bytes())));
        assertThat(codec.decode(codecSpeed.encode(RAW_BYTES.bytes())), is(equalTo(RAW_BYTES.bytes())));
        assertThat(codec.decode(codecBalanced.encode(RAW_BYTES.bytes())), is(equalTo(RAW_BYTES.bytes())));
        assertThat(codec.decode(codecSize.encode(RAW_BYTES.bytes())), is(equalTo(RAW_BYTES.bytes())));
    }

    void assertEncodesSmallerRoundTrip(final CompressionCodec codec) {
        final byte[] input = RAW_BYTES.bytes();

        final byte[] encoded = codec.encode(input);
        assertThat("encoded is smaller", encoded.length, is(lessThan(input.length)));
        assertThat("shaped like zstd", AbstractZstdAwareCompressionCodec.isZstd(encoded), is(true));
        assertThat("round trip decode", codec.decode(encoded), is(equalTo(input)));
    }

    public static byte[] compress(byte[] input, int level) {
        return Zstd.compress(input, level);
    }
}
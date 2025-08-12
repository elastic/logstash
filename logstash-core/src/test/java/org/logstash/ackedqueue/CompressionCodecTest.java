package org.logstash.ackedqueue;

import org.apache.logging.log4j.Logger;
import org.junit.Test;
import org.mockito.Mockito;

import java.security.SecureRandom;
import java.util.Arrays;
import java.util.Set;
import java.util.zip.Deflater;

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
    static final ImmutableByteArrayBarrier DEFLATE_SPEED_BYTES = new ImmutableByteArrayBarrier(deflate(RAW_BYTES.bytes(), Deflater.BEST_SPEED));
    static final ImmutableByteArrayBarrier DEFLATE_BALANCED_BYTES = new ImmutableByteArrayBarrier(deflate(RAW_BYTES.bytes(), Deflater.DEFAULT_COMPRESSION));
    static final ImmutableByteArrayBarrier DEFLATE_SIZE_BYTES = new ImmutableByteArrayBarrier(deflate(RAW_BYTES.bytes(), Deflater.BEST_COMPRESSION));

    private final CompressionCodec codecDisabled = CompressionCodec.fromConfigValue("disabled");
    private final CompressionCodec codecNone = CompressionCodec.fromConfigValue("none");
    private final CompressionCodec codecSpeed = CompressionCodec.fromConfigValue("speed");
    private final CompressionCodec codecBalanced = CompressionCodec.fromConfigValue("balanced");
    private final CompressionCodec codecSize = CompressionCodec.fromConfigValue("size");

    @Test
    public void testDisabledCompressionCodecDecodes() throws Exception {
        final CompressionCodec compressionCodec = CompressionCodec.fromConfigValue("disabled");
        assertDecodesRaw(compressionCodec);

        // ensure true pass-through when compression is disabled, even if the payload looks like DEFLATE
        assertThat(compressionCodec.decode(DEFLATE_SPEED_BYTES.bytes()), is(equalTo(DEFLATE_SPEED_BYTES.bytes())));
        assertThat(compressionCodec.decode(DEFLATE_BALANCED_BYTES.bytes()), is(equalTo(DEFLATE_BALANCED_BYTES.bytes())));
        assertThat(compressionCodec.decode(DEFLATE_SIZE_BYTES.bytes()), is(equalTo(DEFLATE_SIZE_BYTES.bytes())));
    }

    @Test
    public void testDisabledCompressionCodecEncodes() throws Exception {
        final CompressionCodec compressionCodec = CompressionCodec.fromConfigValue("disabled");
        // ensure true pass-through when compression is disabled
        assertThat(compressionCodec.encode(RAW_BYTES.bytes()), is(equalTo(RAW_BYTES.bytes())));
    }

    @Test
    public void testDisabledCompressionCodecLogging() throws Exception {
        final Logger mockLogger = Mockito.mock(Logger.class);
        CompressionCodec.fromConfigValue("disabled", mockLogger);
        Mockito.verify(mockLogger).warn(argThat(stringContainsInOrder("compression support", "disabled")));
    }

    @Test
    public void testNoneCompressionCodecDecodes() throws Exception {
        final CompressionCodec compressionCodec = CompressionCodec.fromConfigValue("none");
        assertDecodesRaw(compressionCodec);
        assertDecodesDeflateAnyLevel(compressionCodec);
        assertDecodesOutputOfAllKnownCompressionCodecs(compressionCodec);
    }

    @Test
    public void testNoneCompressionCodecEncodes() throws Exception {
        final CompressionCodec compressionCodec = CompressionCodec.fromConfigValue("none");
        assertThat(compressionCodec.encode(RAW_BYTES.bytes()), is(equalTo(RAW_BYTES.bytes())));
    }

    @Test
    public void testNoneCompressionCodecLogging() throws Exception {
        final Logger mockLogger = Mockito.mock(Logger.class);
        CompressionCodec.fromConfigValue("none", mockLogger);
        Mockito.verify(mockLogger).info(argThat(stringContainsInOrder("compression support", "enabled", "read-only")));
    }

    @Test
    public void testSpeedCompressionCodecDecodes() throws Exception {
        final CompressionCodec compressionCodec = CompressionCodec.fromConfigValue("speed");
        assertDecodesRaw(compressionCodec);
        assertDecodesDeflateAnyLevel(compressionCodec);
        assertDecodesOutputOfAllKnownCompressionCodecs(compressionCodec);
    }

    @Test
    public void testSpeedCompressionCodecEncodes() throws Exception {
        final CompressionCodec compressionCodec = CompressionCodec.fromConfigValue("speed");
        assertEncodesSmallerRoundTrip(compressionCodec);
    }

    @Test
    public void testSpeedCompressionCodecLogging() throws Exception {
        final Logger mockLogger = Mockito.mock(Logger.class);
        CompressionCodec.fromConfigValue("speed", mockLogger);
        Mockito.verify(mockLogger).info(argThat(stringContainsInOrder("compression support", "enabled", "speed")));
    }

    @Test
    public void testBalancedCompressionCodecDecodes() throws Exception {
        final CompressionCodec compressionCodec = CompressionCodec.fromConfigValue("balanced");
        assertDecodesRaw(compressionCodec);
        assertDecodesDeflateAnyLevel(compressionCodec);
        assertDecodesOutputOfAllKnownCompressionCodecs(compressionCodec);
    }

    @Test
    public void testBalancedCompressionCodecEncodes() throws Exception {
        final CompressionCodec compressionCodec = CompressionCodec.fromConfigValue("balanced");
        assertEncodesSmallerRoundTrip(compressionCodec);
    }

    @Test
    public void testBalancedCompressionCodecLogging() throws Exception {
        final Logger mockLogger = Mockito.mock(Logger.class);
        CompressionCodec.fromConfigValue("balanced", mockLogger);
        Mockito.verify(mockLogger).info(argThat(stringContainsInOrder("compression support", "enabled", "balanced")));
    }

    @Test
    public void testSizeCompressionCodecDecodes() throws Exception {
        final CompressionCodec compressionCodec = CompressionCodec.fromConfigValue("size");
        assertDecodesRaw(compressionCodec);
        assertDecodesDeflateAnyLevel(compressionCodec);
        assertDecodesOutputOfAllKnownCompressionCodecs(compressionCodec);
    }

    @Test
    public void testSizeCompressionCodecEncodes() throws Exception {
        final CompressionCodec compressionCodec = CompressionCodec.fromConfigValue("size");
        assertEncodesSmallerRoundTrip(compressionCodec);
    }

    @Test
    public void testSizeCompressionCodecLogging() throws Exception {
        final Logger mockLogger = Mockito.mock(Logger.class);
        CompressionCodec.fromConfigValue("size", mockLogger);
        Mockito.verify(mockLogger).info(argThat(stringContainsInOrder("compression support", "enabled", "size")));
    }

    @Test(timeout=1000)
    public void testCompressionCodecDecodeTailTruncated() throws Exception {
        final byte[] truncatedInput = copyWithTruncatedTail(DEFLATE_BALANCED_BYTES.bytes(), 32);

        final RuntimeException thrownException = assertThrows(RuntimeException.class, () -> codecNone.decode(truncatedInput));
        assertThat(thrownException.getMessage(), containsString("IOException while decoding"));
        final Throwable rootCause = extractRootCause(thrownException);
        assertThat(rootCause.getMessage(), anyOf(containsString("prematurely reached end"), containsString("incorrect data check")));
    }

    byte[] copyWithTruncatedTail(final byte[] input, final int tailSize) {
        int startIndex = (input.length < tailSize) ? 0 : input.length - tailSize;

        final byte[] result = Arrays.copyOf(input, input.length);
        Arrays.fill(result, startIndex, result.length, (byte) 0);

        return result;
    }

    @Test(timeout=1000)
    public void testCompressionCodecDecodeTailScrambled() throws Exception {
        final byte[] scrambledInput = copyWithScrambledTail(DEFLATE_BALANCED_BYTES.bytes(), 32);

        final RuntimeException thrownException = assertThrows(RuntimeException.class, () -> codecNone.decode(scrambledInput));
        assertThat(thrownException.getMessage(), containsString("IOException while decoding"));
        final Throwable rootCause = extractRootCause(thrownException);
        assertThat(rootCause.getMessage(), anyOf(containsString("prematurely reached end"), containsString("incorrect data check")));
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
        final byte[] nullPaddedInput = copyWithNullPaddedTail(DEFLATE_BALANCED_BYTES.bytes(), 32);

        assertThat(codecNone.decode(nullPaddedInput), is(equalTo(RAW_BYTES.bytes())));
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
        final Set<Integer> levels = Set.of(
                Deflater.DEFAULT_COMPRESSION,
                Deflater.NO_COMPRESSION,
                Deflater.BEST_SPEED,
                2, 3, 4, 5, 6, 7, 8,
                Deflater.BEST_COMPRESSION);

        for (int level : levels) {
            final byte[] deflated = deflate(RAW_BYTES.bytes(), level);
            assertThat(String.format("deflate level %s (%s bytes)", level, deflated.length), codec.decode(deflated), is(equalTo(RAW_BYTES.bytes())));
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
        assertThat("shaped like deflate", AbstractDeflateAwareCompressionCodec.isDeflate(encoded), is(true));
        assertThat("round trip decode", codec.decode(encoded), is(equalTo(input)));
    }

    public static byte[] deflate(byte[] input, int level) {
        final Deflater deflater = new Deflater(level);
        try {
            deflater.setInput(input);
            deflater.finish();

            // output SHOULD be smaller, but will never be 1kb bigger
            byte[] output = new byte[input.length+1024];

            int compressedLength = deflater.deflate(output);
            return Arrays.copyOf(output, compressedLength);
        } finally {
            deflater.end();
        }
    }
}
package org.logstash.ackedqueue;

import org.apache.logging.log4j.Logger;
import org.junit.Test;
import org.mockito.Mockito;

import java.util.Arrays;
import java.util.Set;
import java.util.zip.Deflater;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.*;
import static org.mockito.Matchers.argThat;

public class CompressionCodecTest {
    public static final byte[] RAW_BYTES = (
            "this is a string of text with repeated substrings that is designed to be "+
            "able to be compressed into a string that is smaller than the original input "+
            "so that we can assert that the compression codecs compress strings to be "+
            "smaller than their uncompressed representations").getBytes();
    public static final byte[] DEFLATE_SPEED_BYTES = deflate(RAW_BYTES, Deflater.BEST_SPEED);
    public static final byte[] DEFLATE_BALANCED_BYTES = deflate(RAW_BYTES, Deflater.DEFAULT_COMPRESSION);
    public static final byte[] DEFLATE_SIZE_BYTES = deflate(RAW_BYTES, Deflater.BEST_COMPRESSION);

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
        assertThat(compressionCodec.decode(DEFLATE_SPEED_BYTES), is(equalTo(DEFLATE_SPEED_BYTES)));
        assertThat(compressionCodec.decode(DEFLATE_BALANCED_BYTES), is(equalTo(DEFLATE_BALANCED_BYTES)));
        assertThat(compressionCodec.decode(DEFLATE_SIZE_BYTES), is(equalTo(DEFLATE_SIZE_BYTES)));
    }

    @Test
    public void testDisabledCompressionCodecEncodes() throws Exception {
        final CompressionCodec compressionCodec = CompressionCodec.fromConfigValue("disabled");
        // ensure true pass-through when compression is disabled
        assertThat(compressionCodec.encode(RAW_BYTES), is(equalTo(RAW_BYTES)));
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
        assertThat(compressionCodec.encode(RAW_BYTES), is(equalTo(RAW_BYTES)));
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

    void assertDecodesRaw(final CompressionCodec codec) {
        assertThat(codec.decode(RAW_BYTES), is(equalTo(RAW_BYTES)));
    }

    void assertDecodesDeflateAnyLevel(final CompressionCodec codec) {
        final Set<Integer> levels = Set.of(
                Deflater.DEFAULT_COMPRESSION,
                Deflater.NO_COMPRESSION,
                Deflater.BEST_SPEED,
                2, 3, 4, 5, 6, 7, 8,
                Deflater.BEST_COMPRESSION);

        for (int level : levels) {
            final byte[] deflated = deflate(RAW_BYTES, level);
            assertThat(String.format("deflate level %s", level), codec.decode(deflated), is(equalTo(RAW_BYTES)));
        }
    }

    void assertDecodesOutputOfAllKnownCompressionCodecs(final CompressionCodec codec) {
        assertThat(codec.decode(codecDisabled.encode(RAW_BYTES)), is(equalTo(RAW_BYTES)));
        assertThat(codec.decode(codecNone.encode(RAW_BYTES)), is(equalTo(RAW_BYTES)));
        assertThat(codec.decode(codecSpeed.encode(RAW_BYTES)), is(equalTo(RAW_BYTES)));
        assertThat(codec.decode(codecBalanced.encode(RAW_BYTES)), is(equalTo(RAW_BYTES)));
        assertThat(codec.decode(codecSize.encode(RAW_BYTES)), is(equalTo(RAW_BYTES)));
    }

    void assertEncodesSmallerRoundTrip(final CompressionCodec codec) {
        final byte[] input = RAW_BYTES;

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
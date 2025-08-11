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
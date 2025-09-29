package org.logstash.ackedqueue;

import com.github.luben.zstd.Zstd;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * Subclasses of {@link AbstractZstdAwareCompressionCodec} are {@link CompressionCodec}s that are capable
 * of detecting and decompressing deflate-compressed events. When decoding byte sequences that are <em>NOT</em>
 * deflate-compressed, the given bytes are emitted verbatim.
 */
abstract class AbstractZstdAwareCompressionCodec implements CompressionCodec {
    // log from the concrete class
    protected final Logger logger = LogManager.getLogger(this.getClass());

    @Override
    public byte[] decode(byte[] data) {
        if (!isZstd(data)) {
            return data;
        }
        try {
            final byte[] decoded = Zstd.decompress(data);
            logger.trace("decoded {} -> {}", data.length, decoded.length);
            return decoded;
        } catch (Exception e) {
            throw new RuntimeException("Exception while decoding", e);
        }
    }

    private static final byte[] ZSTD_FRAME_MAGIC = { (byte) 0x28, (byte) 0xB5, (byte) 0x2F, (byte) 0xFD };

    static boolean isZstd(byte[] data) {
        if (data.length < 4) { return false; }

        for (int i = 0; i < 4; i++) {
            if (data[i] != ZSTD_FRAME_MAGIC[i]) { return false; }
        }

        return true;
    }
}

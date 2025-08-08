package org.logstash.ackedqueue;

import com.github.luben.zstd.Zstd;
import org.logstash.util.CleanerThreadLocal;
import org.logstash.util.SetOnceReference;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.lang.ref.Cleaner;
import java.util.zip.DataFormatException;
import java.util.zip.Inflater;

/**
 * Subclasses of {@link AbstractZstdAwareCompressionCodec} are {@link CompressionCodec}s that are capable
 * of detecting and decompressing deflate-compressed events. When decoding byte sequences that are <em>NOT</em>
 * deflate-compressed, the given bytes are emitted verbatim.
 */
abstract class AbstractZstdAwareCompressionCodec implements CompressionCodec {
    @Override
    public byte[] decode(byte[] data) {
        if (!isZstd(data)) {
            return data;
        }
        try {
            return Zstd.decompress(data);
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

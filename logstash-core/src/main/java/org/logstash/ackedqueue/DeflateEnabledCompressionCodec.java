package org.logstash.ackedqueue;

import org.logstash.util.CleanerThreadLocal;
import org.logstash.util.SetOnceReference;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.HexFormat;
import java.util.zip.Deflater;
import java.util.zip.Inflater;

/**
 * A {@link DeflateEnabledCompressionCodec} is a {@link CompressionCodec} that can decode deflate-compressed
 * bytes and performs deflate compression when encoding.
 */
class DeflateEnabledCompressionCodec extends AbstractDeflateAwareCompressionCodec implements CompressionCodec {

    private final CleanerThreadLocal<BufferedDeflater> bufferedDeflaterThreadLocal;

    DeflateEnabledCompressionCodec(final int level) {
        this.bufferedDeflaterThreadLocal = CleanerThreadLocal
                .withInitial(() -> new BufferedDeflater(level))
                .withCleanAction(BufferedDeflater::release, GLOBAL_CLEANER);
    }

    @Override
    public byte[] encode(byte[] data) {
        final BufferedDeflater bufferedDeflater = bufferedDeflaterThreadLocal.get();
        try {
           return bufferedDeflater.encode(data);
        } catch (IOException e) {
            throw new RuntimeException("IOException while encoding", e);
        }
    }

    /**
     * A {@link BufferedDeflater} is a convenience wrapper around the complexities
     * of managing an {@link Inflater}, an intermediate {@code byte[]} buffer, and
     * a {@link ByteArrayOutputStream}. It enables internal reuse of small buffers
     * to reduce allocations.
     */
    static class BufferedDeflater {
        private final Deflater deflater;
        private final byte[] intermediateBuffer;
        private final SetOnceReference<ByteArrayOutputStream> reusableBaosRef;

        public BufferedDeflater(final int level) {
            this.deflater = new Deflater(level);
            this.intermediateBuffer = new byte[1024];
            this.reusableBaosRef = SetOnceReference.unset();
        }

        public byte[] encode(final byte[] data) throws IOException {
            final ByteArrayOutputStream baos = getBaos(data.length);
            try {
                deflater.setInput(data);
                deflater.finish();

                while (!deflater.finished()) {
                    int count = deflater.deflate(intermediateBuffer);
                    baos.write(intermediateBuffer, 0, count);
                }
                byte[] encodedBytes = baos.toByteArray();
                assert isDeflate(encodedBytes) : String.format("invalid deflate signature `%s`", HexFormat.of().formatHex(encodedBytes,0,2));
                return encodedBytes;
            } finally {
                deflater.reset();
                baos.reset();
            }
        }

        public void release() {
            deflater.end();
        }

        private ByteArrayOutputStream getBaos(final int decodedSize) {
            if (decodedSize <= BAOS_SHAREABLE_THRESHOLD_BYTES) {
                return this.reusableBaosRef.offerAndGet(() -> new ByteArrayOutputStream(BAOS_SHAREABLE_THRESHOLD_BYTES));
            }
            return new ByteArrayOutputStream(decodedSize);
        }
    }
}

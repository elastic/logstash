package org.logstash.ackedqueue;

import org.logstash.util.CleanerThreadLocal;
import org.logstash.util.SetOnceReference;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.lang.ref.Cleaner;
import java.util.zip.DataFormatException;
import java.util.zip.Inflater;

/**
 * Subclasses of {@link AbstractDeflateAwareCompressionCodec} are {@link CompressionCodec}s that are capable
 * of detecting and decompressing deflate-compressed events. When decoding byte sequences that are <em>NOT</em>
 * deflate-compressed, the given bytes are emitted verbatim.
 */
abstract class AbstractDeflateAwareCompressionCodec implements CompressionCodec {

    static final int BAOS_SHAREABLE_THRESHOLD_BYTES = 4096;

    static final Cleaner GLOBAL_CLEANER = Cleaner.create();

    private final CleanerThreadLocal<BufferedInflater> bufferedInflaterThreadLocal;

    public AbstractDeflateAwareCompressionCodec() {
        this.bufferedInflaterThreadLocal = CleanerThreadLocal
                .withInitial(BufferedInflater::new)
                .withCleanAction(BufferedInflater::release, GLOBAL_CLEANER);
    }

    @Override
    public byte[] decode(byte[] data) {
        if (!isDeflate(data)) {
            return data;
        }
        final BufferedInflater bufferedInflater = bufferedInflaterThreadLocal.get();
        try {
            return bufferedInflater.decode(data);
        } catch (IOException e) {
            throw new RuntimeException("IOException while decoding", e);
        }
    }

    static boolean isDeflate(byte[] data) {
        if (data.length < 2) { return false; }

        // parse first two bytes as big-endian short
        short header = (short) (((data[0] & 0xFF) << 8) | (data[1] & 0xFF));

        /*
         * RFC-1950: ZLIB Compressed Data Format Specification version 3.3
         * https://www.ietf.org/rfc/rfc1950.txt
         * ┏━━━━ CMF ━━━━━┳━━━━━━━━━━ FLG ━━━━━━━━━━┓
         * ┠─CINFO─┬──CM──╂─FLEVEL─┬─FDICT─┬─FCHECK─┨
         * ┃ 0XXX  │ 1000 ┃ XX     │ 0     │ XXXXX  ┃
         * ┗━━━━━━━┷━━━━━━┻━━━━━━━━┷━━━━━━━┷━━━━━━━━┛
         * CINFO:  0XXX  // always LTE 7 (7 is 32KB window)
         * CM:     1000  // always 8 for deflate
         * DFICT:  0     // always unset (no dictionary)
         *
         *///                  0XXX_1000_XX_0_XXXXX
        short mask = (short) 0b1000_1111_00_1_00000; // bits to keep
        short flip = (short) 0b0000_1000_00_0_00000; // bits to flip
        short goal = (short) 0b0000_0000_00_0_00000; // goal state
        if (((header & mask) ^ flip) != goal) {
            return false;
        }

        // additionally the FCHECK ensures that
        // the big-endian header is a multiple of 31
        return header % 31 == 0;
    }

    /**
     * A {@link BufferedInflater} is a convenience wrapper around the complexities
     * of managing an {@link Inflater}, an intermediate {@code byte[]} buffer, and
     * a {@link ByteArrayOutputStream}. It enables internal reuse of small buffers
     * to reduce allocations.
     */
    static class BufferedInflater {
        private final Inflater inflater;
        private final byte[] intermediateBuffer;
        private final SetOnceReference<ByteArrayOutputStream> reusableBaosRef;

        public BufferedInflater() {
            this.inflater = new Inflater();
            this.intermediateBuffer = new byte[1024];
            this.reusableBaosRef = SetOnceReference.unset();
        }

        public byte[] decode(final byte[] data) throws IOException {
            final ByteArrayOutputStream baos = getBaos(data.length);
            try {
                inflater.setInput(data);

                do {
                    if (inflater.needsInput()) {
                        throw new IOException(String.format("prematurely reached end of encoded value (%s/%s)", inflater.getBytesRead(), inflater.getTotalIn()));
                    }
                    try {
                        int count = inflater.inflate(intermediateBuffer);
                        baos.write(intermediateBuffer, 0, count);
                    } catch (DataFormatException e) {
                        throw new IOException("Failed to decode", e);
                    }
                } while (!inflater.finished());

                return baos.toByteArray();
            } finally {
                inflater.reset();
                baos.reset();
            }
        }

        public void release() {
            inflater.end();
        }

        private ByteArrayOutputStream getBaos(final int encodedSize) {
            if (encodedSize <= BAOS_SHAREABLE_THRESHOLD_BYTES) {
                return this.reusableBaosRef.offerAndGet(() -> new ByteArrayOutputStream(BAOS_SHAREABLE_THRESHOLD_BYTES));
            }
            return new ByteArrayOutputStream(encodedSize);
        }
    }
}

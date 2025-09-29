package org.logstash.ackedqueue;

import java.util.Arrays;

/**
 * An {@link ImmutableByteArrayBarrier} provides an immutability shield around a {@code byte[]}.
 * It stores an inaccessible <em>copy of</em> the provided {@code byte[]}, and makes copies <em>of that copy</em>
 * available via {@link ImmutableByteArrayBarrier#bytes}.
 * @param bytes the byte array
 */
public record ImmutableByteArrayBarrier(byte[] bytes) {
    public ImmutableByteArrayBarrier(byte[] bytes) {
        this.bytes = Arrays.copyOf(bytes, bytes.length);
    }

    @Override
    public byte[] bytes() {
        return Arrays.copyOf(bytes, bytes.length);
    }
}

package org.logstash.ackedqueue.io;

public final class LongVector {

    private int count;

    private long[] data;

    public LongVector(final int size) {
        data = new long[size];
        count = 0;
    }

    /**
     * Store the {@code long} to the underlying {@code long[]}, resizing it if necessary.
     * @param num Long to store
     */
    public void add(final long num) {
        if (data.length < count + 1) {
            final long[] old = data;
            data = new long[(data.length << 1) + 1];
            System.arraycopy(old, 0, data, 0, old.length);
        }
        data[count++] = num;
    }

    /**
     * Get value stored at given index.
     * @param index Array index (only values smaller than {@link LongVector#count} are valid)
     * @return Int
     */
    public long get(final int index) {
        return data[index];
    }

    /**
     * @return Number of elements stored in this instance
     */
    public int size() {
        return count;
    }
}

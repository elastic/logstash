package org.logstash.ackedqueue.io;

final class IntVector {

    private int count;

    private int[] data;

    IntVector() {
        data = new int[1024];
        count = 0;
    }

    /**
     * Store the {@code int} to the underlying {@code int[]}, resizing it if necessary.
     * @param num Int to store
     */
    public void add(final int num) {
        if (data.length < count + 1) {
            final int[] old = data;
            data = new int[data.length << 1];
            System.arraycopy(old, 0, data, 0, old.length);
        }
        data[count++] = num;
    }

    /**
     * Get value stored at given index.
     * @param index Array index (only values < {@link IntVector#count} are valid)
     * @return Int
     */
    public int get(final int index) {
        return data[index];
    }

    /**
     * @return Number of elements stored in this instance
     */
    public int size() {
        return count;
    }
}

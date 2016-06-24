package org.logstash.ackedqueue;


import org.junit.Test;

import java.util.List;

import static org.junit.Assert.*;

public class MemoryPageTest {

    private static byte[] A_BYTES_16 = "aaaaaaaaaaaaaaaa".getBytes();
    private static byte[] B_BYTES_16 = "bbbbbbbbbbbbbbbb".getBytes();

    // without acks

    @Test
    public void testSingleWriteRead() {
        MemoryPage qp = new MemoryPage(1024);
        int head = qp.write(A_BYTES_16);
        assertEquals(A_BYTES_16.length + MemoryPage.OVERHEAD_BYTES, head);
        assertEquals(1, qp.getPageState().unusedCount());
        List<Element> items = qp.read(2);
        assertEquals(1, items.size());
        assertArrayEquals(A_BYTES_16, items.get(0).getData());
        assertEquals(0, qp.getPageState().unusedCount());
    }

    @Test
    public void testOverflow() {
        MemoryPage qp = new MemoryPage(15);
        assertFalse(qp.writable(16));
        assertEquals(0, qp.write(A_BYTES_16));

        assertTrue(qp.writable(15 - MemoryPage.OVERHEAD_BYTES));
        assertFalse(qp.writable(15 - MemoryPage.OVERHEAD_BYTES + 1));
    }

    @Test
    public void testDoubleWriteRead() {
        MemoryPage qp = new MemoryPage(1024);
        int head = qp.write(A_BYTES_16);
        assertEquals(A_BYTES_16.length + MemoryPage.OVERHEAD_BYTES, head);
        assertEquals(1, qp.getPageState().unusedCount());

        head = qp.write(B_BYTES_16);
        assertEquals((B_BYTES_16.length + MemoryPage.OVERHEAD_BYTES) * 2, head);
        assertEquals(2, qp.getPageState().unusedCount());

        List<Element> items = qp.read(2);
        assertEquals(0, qp.getPageState().unusedCount());

        assertEquals(2, items.size());
        assertArrayEquals(A_BYTES_16, items.get(0).getData());
        assertArrayEquals(B_BYTES_16, items.get(1).getData());
    }

    @Test
    public void testDoubleWriteSingleRead() {
        MemoryPage qp = new MemoryPage(1024);
        int head = qp.write(A_BYTES_16);
        assertEquals(A_BYTES_16.length + MemoryPage.OVERHEAD_BYTES, head);
        assertEquals(1, qp.getPageState().unusedCount());

        head = qp.write(B_BYTES_16);
        assertEquals((B_BYTES_16.length + MemoryPage.OVERHEAD_BYTES) * 2, head);
        assertEquals(2, qp.getPageState().unusedCount());

        List<Element> items = qp.read(1);
        assertEquals(1, qp.getPageState().unusedCount());

        assertEquals(1, items.size());
        assertArrayEquals(A_BYTES_16, items.get(0).getData());

        items = qp.read(1);
        assertEquals(0, qp.getPageState().unusedCount());

        assertEquals(1, items.size());
        assertArrayEquals(B_BYTES_16, items.get(0).getData());
    }

    @Test
    public void testLargerRead() {
        MemoryPage qp = new MemoryPage(1024);
        qp.write(A_BYTES_16);
        qp.write(B_BYTES_16);
        assertEquals(2, qp.getPageState().unusedCount());

        List<Element> items = qp.read(3);
        assertEquals(0, qp.getPageState().unusedCount());
        assertEquals(2, items.size());
    }

    @Test
    public void testEmptyRead() {
        MemoryPage qp = new MemoryPage(1024);
        qp.write(A_BYTES_16);
        qp.write(B_BYTES_16);
        assertEquals(2, qp.getPageState().unusedCount());

        List<Element> items = qp.read(2);
        assertEquals(0, qp.getPageState().unusedCount());
        assertEquals(2, items.size());

        items = qp.read(2);
        assertEquals(0, qp.getPageState().unusedCount());
        assertEquals(0, items.size());
    }

    @Test
    public void testWriteReadReset() {
        MemoryPage qp = new MemoryPage(1024);
        qp.write(A_BYTES_16);
        qp.write(B_BYTES_16);

        List<Element> items = qp.read(1);
        assertEquals(1, items.size());
        items = qp.read(1);
        assertEquals(1, items.size());

        assertEquals(0, qp.getPageState().unusedCount());

        qp.getPageState().resetUnused();

        // all items are now maked as unused, we should be able to re-read all items
        assertEquals(2, qp.getPageState().unusedCount());

        items = qp.read(1);
        assertEquals(1, items.size());
        items = qp.read(1);
        assertEquals(1, items.size());

        assertEquals(0, qp.getPageState().unusedCount());
    }

    // with acks

    @Test
    public void testWriteReadAckReset() {
        MemoryPage qp = new MemoryPage(1024);
        qp.write(A_BYTES_16);
        qp.write(B_BYTES_16);

        List<Element> items = qp.read(1);
        assertEquals(1, items.size());
        qp.ack(items);

        items = qp.read(1);
        assertEquals(1, items.size());
        qp.ack(items);

        assertEquals(0, qp.getPageState().unusedCount());

        qp.getPageState().resetUnused();

        assertEquals(0, qp.getPageState().unusedCount());
    }

    @Test
    public void testWriteReadPartialAckReset() {
        MemoryPage qp = new MemoryPage(1024);
        qp.write(A_BYTES_16);
        qp.write(B_BYTES_16);

        List<Element> items = qp.read(1);
        assertEquals(1, items.size());

        assertEquals(1, qp.getPageState().unusedCount());

        qp.ack(items);

        assertEquals(1, qp.getPageState().unusedCount());

        qp.getPageState().resetUnused();

        assertEquals(1, qp.getPageState().unusedCount());
    }

    @Test
    public void testWritePartialAckReset() {
        MemoryPage qp = new MemoryPage(1024);
        qp.write(A_BYTES_16);
        qp.write(B_BYTES_16);

        List<Element> items = qp.read(1);
        qp.getPageState().resetUnused();

        assertEquals(2, qp.getPageState().unusedCount());

        qp.ack(items);

        assertEquals(1, qp.getPageState().unusedCount());
    }

    @Test
    public void testWritePartialAckRead() {
        MemoryPage qp = new MemoryPage(1024);
        qp.write(A_BYTES_16);
        qp.write(B_BYTES_16);

        List<Element> items = qp.read(1);
        qp.getPageState().resetUnused();

        assertEquals(2, qp.getPageState().unusedCount());

        qp.ack(items);

        items = qp.read(2);
        assertEquals(1, items.size());
    }
}


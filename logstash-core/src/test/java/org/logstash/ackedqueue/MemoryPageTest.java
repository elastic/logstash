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
        MemoryPage mp = new MemoryPage(1024);
        int head = mp.write(A_BYTES_16);
        assertEquals(A_BYTES_16.length + MemoryPage.OVERHEAD_BYTES, head);
        assertEquals(1, mp.getPageState().unusedCount());
        List<Element> items = mp.read(2);
        assertEquals(1, items.size());
        assertArrayEquals(A_BYTES_16, items.get(0).getData());
        assertEquals(0, mp.getPageState().unusedCount());
    }

    @Test
    public void testOverflow() {
        MemoryPage mp = new MemoryPage(15);
        assertFalse(mp.writable(16));
        assertEquals(0, mp.write(A_BYTES_16));

        assertTrue(mp.writable(15 - MemoryPage.OVERHEAD_BYTES));
        assertFalse(mp.writable(15 - MemoryPage.OVERHEAD_BYTES + 1));
    }

    @Test
    public void testDoubleWriteRead() {
        MemoryPage mp = new MemoryPage(1024);
        int head = mp.write(A_BYTES_16);
        assertEquals(A_BYTES_16.length + MemoryPage.OVERHEAD_BYTES, head);
        assertEquals(1, mp.getPageState().unusedCount());

        head = mp.write(B_BYTES_16);
        assertEquals((B_BYTES_16.length + MemoryPage.OVERHEAD_BYTES) * 2, head);
        assertEquals(2, mp.getPageState().unusedCount());

        List<Element> items = mp.read(2);
        assertEquals(0, mp.getPageState().unusedCount());

        assertEquals(2, items.size());
        assertArrayEquals(A_BYTES_16, items.get(0).getData());
        assertArrayEquals(B_BYTES_16, items.get(1).getData());
    }

    @Test
    public void testDoubleWriteSingleRead() {
        MemoryPage mp = new MemoryPage(1024);
        int head = mp.write(A_BYTES_16);
        assertEquals(A_BYTES_16.length + MemoryPage.OVERHEAD_BYTES, head);
        assertEquals(1, mp.getPageState().unusedCount());

        head = mp.write(B_BYTES_16);
        assertEquals((B_BYTES_16.length + MemoryPage.OVERHEAD_BYTES) * 2, head);
        assertEquals(2, mp.getPageState().unusedCount());

        List<Element> items = mp.read(1);
        assertEquals(1, mp.getPageState().unusedCount());

        assertEquals(1, items.size());
        assertArrayEquals(A_BYTES_16, items.get(0).getData());

        items = mp.read(1);
        assertEquals(0, mp.getPageState().unusedCount());

        assertEquals(1, items.size());
        assertArrayEquals(B_BYTES_16, items.get(0).getData());
    }

    @Test
    public void testLargerRead() {
        MemoryPage mp = new MemoryPage(1024);
        mp.write(A_BYTES_16);
        mp.write(B_BYTES_16);
        assertEquals(2, mp.getPageState().unusedCount());

        List<Element> items = mp.read(3);
        assertEquals(0, mp.getPageState().unusedCount());
        assertEquals(2, items.size());
    }

    @Test
    public void testEmptyRead() {
        MemoryPage mp = new MemoryPage(1024);
        mp.write(A_BYTES_16);
        mp.write(B_BYTES_16);
        assertEquals(2, mp.getPageState().unusedCount());

        List<Element> items = mp.read(2);
        assertEquals(0, mp.getPageState().unusedCount());
        assertEquals(2, items.size());

        items = mp.read(2);
        assertEquals(0, mp.getPageState().unusedCount());
        assertEquals(0, items.size());
    }

    @Test
    public void testWriteReadReset() {
        MemoryPage mp = new MemoryPage(1024);
        mp.write(A_BYTES_16);
        mp.write(B_BYTES_16);

        List<Element> items = mp.read(1);
        assertEquals(1, items.size());
        items = mp.read(1);
        assertEquals(1, items.size());

        assertEquals(0, mp.getPageState().unusedCount());

        mp.getPageState().resetUnused();

        // all items are now maked as unused, we should be able to re-read all items
        assertEquals(2, mp.getPageState().unusedCount());

        items = mp.read(1);
        assertEquals(1, items.size());
        items = mp.read(1);
        assertEquals(1, items.size());

        assertEquals(0, mp.getPageState().unusedCount());
    }

    // with acks

    @Test
    public void testWriteReadAckReset() {
        MemoryPage mp = new MemoryPage(1024);
        mp.write(A_BYTES_16);
        mp.write(B_BYTES_16);

        List<Element> items = mp.read(1);
        assertEquals(1, items.size());
        mp.ack(items);

        items = mp.read(1);
        assertEquals(1, items.size());
        mp.ack(items);

        assertEquals(0, mp.getPageState().unusedCount());

        mp.getPageState().resetUnused();

        assertEquals(0, mp.getPageState().unusedCount());
    }

    @Test
    public void testWriteReadPartialAckReset() {
        MemoryPage mp = new MemoryPage(1024);
        mp.write(A_BYTES_16);
        mp.write(B_BYTES_16);

        List<Element> items = mp.read(1);
        assertEquals(1, items.size());

        assertEquals(1, mp.getPageState().unusedCount());

        mp.ack(items);

        assertEquals(1, mp.getPageState().unusedCount());

        mp.getPageState().resetUnused();

        assertEquals(1, mp.getPageState().unusedCount());
    }

    @Test
    public void testWritePartialAckReset() {
        MemoryPage mp = new MemoryPage(1024);
        mp.write(A_BYTES_16);
        mp.write(B_BYTES_16);

        List<Element> items = mp.read(1);
        mp.getPageState().resetUnused();

        assertEquals(2, mp.getPageState().unusedCount());

        mp.ack(items);

        assertEquals(1, mp.getPageState().unusedCount());
    }

    @Test
    public void testWritePartialAckRead() {
        MemoryPage mp = new MemoryPage(1024);
        mp.write(A_BYTES_16);
        mp.write(B_BYTES_16);

        List<Element> items = mp.read(1);
        mp.getPageState().resetUnused();

        assertEquals(2, mp.getPageState().unusedCount());

        mp.ack(items);

        items = mp.read(2);
        assertEquals(1, items.size());
    }
}


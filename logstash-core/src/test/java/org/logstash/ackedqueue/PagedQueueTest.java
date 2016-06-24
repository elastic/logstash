package org.logstash.ackedqueue;

import org.junit.Test;
import static org.junit.Assert.*;

import java.io.FileNotFoundException;
import java.util.List;

public class PagedQueueTest {

    private static byte[] A_BYTES_16 = "aaaaaaaaaaaaaaaa".getBytes();
    private static byte[] B_BYTES_16 = "bbbbbbbbbbbbbbbb".getBytes();

//    @Test(expected = FileNotFoundException.class)
//    public void testOpenInvalidPath() throws FileNotFoundException {
//        PagedQueue pq = new VolatilePagedQueue(1024);
//    }

    @Test
    public void testOpenValidPath() throws FileNotFoundException {
        PagedQueue pq = new VolatilePagedQueue(1024);
    }


    @Test
    public void testSingleWriteRead() throws FileNotFoundException {
        PagedQueue pq = new VolatilePagedQueue(A_BYTES_16.length + Page.OVERHEAD_BYTES);
        pq.write(A_BYTES_16);
        List<Element> result = pq.read(1);
        assertEquals(1 , result.size());
        assertArrayEquals(A_BYTES_16, result.get(0).getData());
        assertEquals(0, result.get(0).getPageIndex());
        assertEquals(0, result.get(0).getPageOffet());
    }

    @Test
    public void testSingleWriteBiggerRead() throws FileNotFoundException {
        PagedQueue pq = new VolatilePagedQueue(A_BYTES_16.length + Page.OVERHEAD_BYTES);
        pq.write(A_BYTES_16);
        List<Element> result = pq.read(2);
        assertEquals(1 , result.size());
        assertArrayEquals(A_BYTES_16, result.get(0).getData());
        assertEquals(0, result.get(0).getPageIndex());
        assertEquals(0, result.get(0).getPageOffet());
    }

    @Test
    public void testSingleWriteDualRead() throws FileNotFoundException {
        PagedQueue pq = new VolatilePagedQueue(A_BYTES_16.length + Page.OVERHEAD_BYTES);
        pq.write(A_BYTES_16);
        List<Element> result = pq.read(1);
        assertEquals(1 , result.size());
        result = pq.read(1);
        assertEquals(0, result.size());
    }

    @Test
    public void testMultipleWriteSingleRead() throws FileNotFoundException {
        PagedQueue pq = new VolatilePagedQueue(A_BYTES_16.length + Page.OVERHEAD_BYTES);
        pq.write(A_BYTES_16);
        pq.write(B_BYTES_16);
        List<Element> result = pq.read(2);
        assertEquals(2 , result.size());

        assertArrayEquals(A_BYTES_16, result.get(0).getData());
        assertArrayEquals(B_BYTES_16, result.get(1).getData());

        result = pq.read(1);
        assertEquals(0, result.size());
    }

    @Test
    public void testMultipleWriteRead() throws FileNotFoundException {
        PagedQueue pq = new VolatilePagedQueue(A_BYTES_16.length + Page.OVERHEAD_BYTES);
        pq.write(A_BYTES_16);
        pq.write(B_BYTES_16);
        List<Element> result = pq.read(1);
        assertEquals(1, result.size());
        assertArrayEquals(A_BYTES_16, result.get(0).getData());

        result = pq.read(1);
        assertEquals(1, result.size());
        assertArrayEquals(B_BYTES_16, result.get(0).getData());

        result = pq.read(1);
        assertEquals(0 , result.size());
    }

    @Test
    public void testMultipleWriteBiggerRead() throws FileNotFoundException {
        PagedQueue pq = new VolatilePagedQueue(A_BYTES_16.length + Page.OVERHEAD_BYTES);
        pq.write(A_BYTES_16);
        pq.write(B_BYTES_16);
        List<Element> result = pq.read(3);
        assertEquals(2, result.size());
        assertArrayEquals(A_BYTES_16, result.get(0).getData());
        assertArrayEquals(B_BYTES_16, result.get(1).getData());

        result = pq.read(1);
        assertEquals(0 , result.size());
    }

    @Test
    public void testSingleWriteReadResetRead() throws FileNotFoundException {
        PagedQueue pq = new VolatilePagedQueue(A_BYTES_16.length + Page.OVERHEAD_BYTES);
        pq.write(A_BYTES_16);
        List<Element> result = pq.read(1);
        assertEquals(1 , result.size());

        pq.resetUnused();

        result = pq.read(1);
        assertEquals(1 , result.size());
    }

    @Test
    public void testMultipleWriteReadResetRead() throws FileNotFoundException {
        PagedQueue pq = new VolatilePagedQueue(A_BYTES_16.length + Page.OVERHEAD_BYTES);
        pq.write(A_BYTES_16);
        pq.write(B_BYTES_16);
        List<Element> result = pq.read(2);
        assertEquals(2, result.size());

        pq.resetUnused();

        result = pq.read(2);
        assertEquals(2, result.size());
    }

    // acking

    @Test
    public void testMultipleWriteReadAckResetRead() throws FileNotFoundException {
        PagedQueue pq = new VolatilePagedQueue(A_BYTES_16.length + Page.OVERHEAD_BYTES);
        pq.write(A_BYTES_16);
        pq.write(B_BYTES_16);
        List<Element> result = pq.read(2);
        assertEquals(2, result.size());

        pq.ack(result);
        pq.resetUnused();

        result = pq.read(2);
        assertEquals(0, result.size());
    }

    @Test
    public void testWritePartialAckRead()  throws FileNotFoundException {
        PagedQueue pq = new VolatilePagedQueue(A_BYTES_16.length + Page.OVERHEAD_BYTES);
        pq.write(A_BYTES_16);
        pq.write(B_BYTES_16);

        List<Element> result = pq.read(1);
        assertArrayEquals(A_BYTES_16, result.get(0).getData());
        pq.resetUnused();

        pq.ack(result);

        result = pq.read(2);
        assertEquals(1, result.size());
        assertArrayEquals(B_BYTES_16, result.get(0).getData());
    }

    @Test
    public void testWriteFulllAckRead()  throws FileNotFoundException {
        PagedQueue pq = new VolatilePagedQueue(A_BYTES_16.length + Page.OVERHEAD_BYTES);
        pq.write(A_BYTES_16);
        pq.write(B_BYTES_16);

        List<Element> result = pq.read(2);
        assertArrayEquals(A_BYTES_16, result.get(0).getData());
        assertArrayEquals(B_BYTES_16, result.get(1).getData());
        pq.resetUnused();

        pq.ack(result);

        result = pq.read(2);
        assertEquals(0, result.size());
    }
}


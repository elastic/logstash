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
//        PagedQueue ph = new VolatilePagedQueue(1024);
//    }

    @Test
    public void testOpenValidPath() throws FileNotFoundException {
        PagedQueue ph = new VolatilePagedQueue(1024);
    }


    @Test
    public void testSingleWriteRead() throws FileNotFoundException {
        PagedQueue ph = new VolatilePagedQueue(A_BYTES_16.length + Page.OVERHEAD_BYTES);
        ph.write(A_BYTES_16);
        List<Element> result = ph.read(1);
        assertEquals(1 , result.size());
        assertArrayEquals(A_BYTES_16, result.get(0).getData());
        assertEquals(0, result.get(0).getPageIndex());
        assertEquals(0, result.get(0).getPageOffet());
    }

    @Test
    public void testSingleWriteBiggerRead() throws FileNotFoundException {
        PagedQueue ph = new VolatilePagedQueue(A_BYTES_16.length + Page.OVERHEAD_BYTES);
        ph.write(A_BYTES_16);
        List<Element> result = ph.read(2);
        assertEquals(1 , result.size());
        assertArrayEquals(A_BYTES_16, result.get(0).getData());
        assertEquals(0, result.get(0).getPageIndex());
        assertEquals(0, result.get(0).getPageOffet());
    }

    @Test
    public void testSingleWriteDualRead() throws FileNotFoundException {
        PagedQueue ph = new VolatilePagedQueue(A_BYTES_16.length + Page.OVERHEAD_BYTES);
        ph.write(A_BYTES_16);
        List<Element> result = ph.read(1);
        assertEquals(1 , result.size());
        result = ph.read(1);
        assertEquals(0, result.size());
    }

    @Test
    public void testMultipleWriteSingleRead() throws FileNotFoundException {
        PagedQueue ph = new VolatilePagedQueue(A_BYTES_16.length + Page.OVERHEAD_BYTES);
        ph.write(A_BYTES_16);
        ph.write(B_BYTES_16);
        List<Element> result = ph.read(2);
        assertEquals(2 , result.size());

        assertArrayEquals(A_BYTES_16, result.get(0).getData());
        assertArrayEquals(B_BYTES_16, result.get(1).getData());

        result = ph.read(1);
        assertEquals(0, result.size());
    }

    @Test
    public void testMultipleWriteRead() throws FileNotFoundException {
        PagedQueue ph = new VolatilePagedQueue(A_BYTES_16.length + Page.OVERHEAD_BYTES);
        ph.write(A_BYTES_16);
        ph.write(B_BYTES_16);
        List<Element> result = ph.read(1);
        assertEquals(1, result.size());
        assertArrayEquals(A_BYTES_16, result.get(0).getData());

        result = ph.read(1);
        assertEquals(1, result.size());
        assertArrayEquals(B_BYTES_16, result.get(0).getData());

        result = ph.read(1);
        assertEquals(0 , result.size());
    }

    @Test
    public void testMultipleWriteBiggerRead() throws FileNotFoundException {
        PagedQueue ph = new VolatilePagedQueue(A_BYTES_16.length + Page.OVERHEAD_BYTES);
        ph.write(A_BYTES_16);
        ph.write(B_BYTES_16);
        List<Element> result = ph.read(3);
        assertEquals(2, result.size());
        assertArrayEquals(A_BYTES_16, result.get(0).getData());
        assertArrayEquals(B_BYTES_16, result.get(1).getData());

        result = ph.read(1);
        assertEquals(0 , result.size());
    }

    @Test
    public void testSingleWriteReadResetRead() throws FileNotFoundException {
        PagedQueue ph = new VolatilePagedQueue(A_BYTES_16.length + Page.OVERHEAD_BYTES);
        ph.write(A_BYTES_16);
        List<Element> result = ph.read(1);
        assertEquals(1 , result.size());

        ph.resetUnused();

        result = ph.read(1);
        assertEquals(1 , result.size());
    }

    @Test
    public void testMultipleWriteReadResetRead() throws FileNotFoundException {
        PagedQueue ph = new VolatilePagedQueue(A_BYTES_16.length + Page.OVERHEAD_BYTES);
        ph.write(A_BYTES_16);
        ph.write(B_BYTES_16);
        List<Element> result = ph.read(2);
        assertEquals(2, result.size());

        ph.resetUnused();

        result = ph.read(2);
        assertEquals(2, result.size());
    }

    // acking

    @Test
    public void testMultipleWriteReadAckResetRead() throws FileNotFoundException {
        PagedQueue ph = new VolatilePagedQueue(A_BYTES_16.length + Page.OVERHEAD_BYTES);
        ph.write(A_BYTES_16);
        ph.write(B_BYTES_16);
        List<Element> result = ph.read(2);
        assertEquals(2, result.size());

        ph.ack(result);
        ph.resetUnused();

        result = ph.read(2);
        assertEquals(0, result.size());
    }

    @Test
    public void testWritePartialAckRead()  throws FileNotFoundException {
        PagedQueue ph = new VolatilePagedQueue(A_BYTES_16.length + Page.OVERHEAD_BYTES);
        ph.write(A_BYTES_16);
        ph.write(B_BYTES_16);

        List<Element> result = ph.read(1);
        assertArrayEquals(A_BYTES_16, result.get(0).getData());
        ph.resetUnused();

        ph.ack(result);

        result = ph.read(2);
        assertEquals(1, result.size());
        assertArrayEquals(B_BYTES_16, result.get(0).getData());
    }

    @Test
    public void testWriteFulllAckRead()  throws FileNotFoundException {
        PagedQueue ph = new VolatilePagedQueue(A_BYTES_16.length + Page.OVERHEAD_BYTES);
        ph.write(A_BYTES_16);
        ph.write(B_BYTES_16);

        List<Element> result = ph.read(2);
        assertArrayEquals(A_BYTES_16, result.get(0).getData());
        assertArrayEquals(B_BYTES_16, result.get(1).getData());
        ph.resetUnused();

        ph.ack(result);

        result = ph.read(2);
        assertEquals(0, result.size());
    }
}


package org.logstash.previous_ackedqueue;

import org.junit.Before;
import org.junit.Test;

import java.io.FileNotFoundException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

import static org.junit.Assert.*;

public class QueueTest {


    private List<String> items;
    private int MAX_ITEMS = 9999;

    @Before
    public void setUp() {
        assert MAX_ITEMS <= 9999; // should not be larger than 4 bytes in string representation

        items = new ArrayList<>();

        for (int i = 0; i < MAX_ITEMS; i++) {
            items.add(String.valueOf(i));
        }
    }

    private void assertSameItems(List<Element> l) {
        assertEquals(items, l.stream().map(e -> new String(e.getData())).collect(Collectors.toList()));
    }

    @Test
    public void testStringListAssertion() {
        List<String> l1 = new ArrayList<>();
        List<String> l2 = new ArrayList<>();
        byte[] b = {49};

        l1.add(String.valueOf(1));
        l2.add(new String(b));
        assertEquals(l1, l2);
    }

    @Test
    public void testPushPopUseBatch() throws FileNotFoundException {
        Queue q = new VolatileQueue(27); // somewhere a bit bigger than twice the data size (4 bytes here)

        for (String s : items) {
            q.push(s.getBytes());
        }

        List<Element> result = q.use(MAX_ITEMS);
        assertEquals(MAX_ITEMS, result.size());
        assertNull(q.use());
        assertSameItems(result);
    }

    @Test
    public void testPushPopUseBatchResetPop() throws FileNotFoundException {
        Queue q = new VolatileQueue(27); // somewhere a bit bigger than twice the data size (4 bytes here)q.open();

        for (String s : items) {
            q.push(s.getBytes());
        }

        List<Element> result = q.use(MAX_ITEMS);
        assertEquals(MAX_ITEMS, result.size());
        assertNull(q.use());
        assertTrue(q.use(MAX_ITEMS).isEmpty());
        assertSameItems(result);

        q.resetUsed();

        result = q.use(MAX_ITEMS);
        assertEquals(MAX_ITEMS, result.size());
        assertNull(q.use());
        assertSameItems(result);
    }

    @Test
    public void testPushPopUseSingle() throws FileNotFoundException {
        Queue q = new VolatileQueue(27); // somewhere a bit bigger than twice the data size (4 bytes here)

        for (String s : items) {
            q.push(s.getBytes());
        }

        List<Element> result = new ArrayList<>();
        Element e;

        while ((e = q.use()) != null) {
            result.add(e);
        }

        assertEquals(MAX_ITEMS, result.size());
        assertNull(q.use());
        assertTrue(q.use(MAX_ITEMS).isEmpty());
        assertSameItems(result);
    }

    @Test
    public void testPushPopUseSingleResetPop() throws FileNotFoundException {
        Queue q = new VolatileQueue(27); // somewhere a bit bigger than twice the data size (4 bytes here)

        for (String s : items) {
            q.push(s.getBytes());
        }

        List<Element> result = new ArrayList<>();
        Element e;

        while ((e = q.use()) != null) {
            result.add(e);
        }

        assertEquals(MAX_ITEMS, result.size());
        assertNull(q.use());
        assertSameItems(result);

        q.resetUsed();

        result.clear();
        while ((e = q.use()) != null) {
            result.add(e);
        }

        assertEquals(MAX_ITEMS, result.size());
        assertNull(q.use());
        assertTrue(q.use(MAX_ITEMS).isEmpty());
        assertSameItems(result);
    }

    @Test
    public void testPushPopUseBatchAckResetPop() throws FileNotFoundException {
        Queue q = new VolatileQueue(27); // somewhere a bit bigger than twice the data size (4 bytes here)

        for (String s : items) {
            q.push(s.getBytes());
        }

        List<Element> result = q.use(MAX_ITEMS);
        q.ack(result);

        q.resetUsed();

        result = q.use(MAX_ITEMS);
        assertTrue(result.isEmpty());
    }

    @Test
    public void testPushPopUseBatchPartialAckResetPop() throws FileNotFoundException {
        Queue q = new VolatileQueue(27); // somewhere a bit bigger than twice the data size (4 bytes here)

        for (String s : items) {
            q.push(s.getBytes());
        }

        List<Element> result = q.use(MAX_ITEMS);

        List<Element> acked = result.stream().filter(e -> e.getPageOffet() %2 == 0).collect(Collectors.toList());
        List<Element> unacked = new ArrayList<>(result);
        unacked.removeAll(acked);

        q.ack(acked);

        q.resetUsed();

        result = q.use(MAX_ITEMS);
        assertEquals(unacked.size(), result.size());
        List l1 = unacked.stream().map(e -> new String(e.getData())).collect(Collectors.toList());
        List l2 = result.stream().map(e -> new String(e.getData())).collect(Collectors.toList());
        Collections.sort(l1);
        Collections.sort(l2);
        assertEquals(l1, l2);

        assertTrue(q.use(MAX_ITEMS).isEmpty());

        q.ack(unacked);
        assertTrue(q.use(MAX_ITEMS).isEmpty());

        q.resetUsed();
        assertTrue(q.use(MAX_ITEMS).isEmpty());
    }
}

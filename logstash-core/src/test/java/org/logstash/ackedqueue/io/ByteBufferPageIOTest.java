package org.logstash.ackedqueue.io;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;
import org.junit.runners.Parameterized.Parameter;
import org.junit.runners.Parameterized.Parameters;
import org.logstash.ackedqueue.Queueable;
import org.logstash.ackedqueue.SequencedList;
import org.logstash.ackedqueue.StringElement;

import java.io.IOException;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.stream.Collectors;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.logstash.ackedqueue.QueueTestHelpers.BYTE_BUF_PAGEIO_MIN_CAPACITY;
import static org.logstash.ackedqueue.QueueTestHelpers.singleElementCapacityForByteBufferPageIO;

public class ByteBufferPageIOTest {

    // convert any checked exceptions into uncheck RuntimeException
    public static <V> V uncheck(Callable<V> callable) {
        try {
            return callable.call();
        } catch (RuntimeException e) {
            throw e;
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    private interface BufferGenerator {
        byte[] generate() throws IOException;
    }

    private static int CAPACITY = 1024;

    private static ByteBufferPageIO newEmptyPageIO() throws IOException {
        return newEmptyPageIO(CAPACITY);
    }

    private static ByteBufferPageIO newEmptyPageIO(int capacity) throws IOException {
        ByteBufferPageIO io = new ByteBufferPageIO(capacity);
        io.create();
        return io;
    }

    private static ByteBufferPageIO newPageIO(int capacity, byte[] bytes) throws IOException {
        return new ByteBufferPageIO(capacity, bytes);
    }

    private Queueable buildStringElement(String str) {
        return new StringElement(str);
    }

    @Test
    public void getWritePosition() throws IOException {
        assertThat(newEmptyPageIO().getWritePosition(), is(equalTo(1)));
    }

    @Test
    public void getElementCount() throws IOException {
        assertThat(newEmptyPageIO().getElementCount(), is(equalTo(0)));
    }

    @Test
    public void getStartSeqNum() throws IOException {
        assertThat(newEmptyPageIO().getMinSeqNum(), is(equalTo(0L)));
    }

    @Test
    public void hasSpace() throws IOException {
        assertThat(newEmptyPageIO(BYTE_BUF_PAGEIO_MIN_CAPACITY).hasSpace(0), is(true));
        assertThat(newEmptyPageIO(BYTE_BUF_PAGEIO_MIN_CAPACITY).hasSpace(1), is(false));
    }

    @Test
    public void hasSpaceAfterWrite() throws IOException {
        Queueable element = new StringElement("foobarbaz");
        long seqNum = 1L;

        ByteBufferPageIO io = newEmptyPageIO(singleElementCapacityForByteBufferPageIO(element));

        assertThat(io.hasSpace(element.serialize().length), is(true));
        io.write(element.serialize(), seqNum);
        assertThat(io.hasSpace(element.serialize().length), is(false));
        assertThat(io.hasSpace(1), is(false));
    }

    @Test
    public void write() throws IOException {
        Queueable element = new StringElement("foobarbaz");
        long seqNum = 42L;
        ByteBufferPageIO io = newEmptyPageIO();
        io.write(element.serialize(), seqNum);
        assertThat(io.getWritePosition(), is(equalTo(singleElementCapacityForByteBufferPageIO(element))));
        assertThat(io.getElementCount(), is(equalTo(1)));
        assertThat(io.getMinSeqNum(), is(equalTo(seqNum)));
    }

    @Test
    public void openValidState() throws IOException {
        Queueable element = new StringElement("foobarbaz");
        long seqNum = 42L;
        ByteBufferPageIO io = newEmptyPageIO();
        io.write(element.serialize(), seqNum);

        byte[] initialState = io.dump();
        io = newPageIO(initialState.length, initialState);
        io.open(seqNum, 1);
        assertThat(io.getElementCount(), is(equalTo(1)));
        assertThat(io.getMinSeqNum(), is(equalTo(seqNum)));
    }

    @Test
    public void recoversValidState() throws IOException {
        Queueable element = new StringElement("foobarbaz");
        long seqNum = 42L;
        ByteBufferPageIO io = newEmptyPageIO();
        io.write(element.serialize(), seqNum);

        byte[] initialState = io.dump();
        io = newPageIO(initialState.length, initialState);
        io.recover();
        assertThat(io.getElementCount(), is(equalTo(1)));
        assertThat(io.getMinSeqNum(), is(equalTo(seqNum)));
    }

    @Test
    public void recoverEmptyWriteRecover() throws IOException {
        Queueable element = new StringElement("foobarbaz");
        long seqNum = 42L;
        ByteBufferPageIO io = newEmptyPageIO();
        byte[] initialState = io.dump();

        io = newPageIO(initialState.length, initialState);
        io.recover();
        assertThat(io.getElementCount(), is(equalTo(0)));

        io.write(element.serialize(), seqNum);
        initialState = io.dump();

        io = newPageIO(initialState.length, initialState);
        io.recover();
        assertThat(io.getElementCount(), is(equalTo(1)));
        assertThat(io.getMinSeqNum(), is(equalTo(seqNum)));
    }

    @Test
    public void recoverNonEmptyWriteRecover() throws IOException {
        Queueable element = new StringElement("foobarbaz");

        ByteBufferPageIO io = newEmptyPageIO();
        io.write(element.serialize(), 1L);
        byte[] initialState = io.dump();

        io = newPageIO(initialState.length, initialState);
        io.recover();
        assertThat(io.getElementCount(), is(equalTo(1)));

        io.write(element.serialize(), 2L);
        initialState = io.dump();

        io = newPageIO(initialState.length, initialState);
        io.recover();
        assertThat(io.getElementCount(), is(equalTo(2)));
    }

    @Test(expected = IOException.class)
    public void openUnexpectedSeqNum() throws IOException {
        Queueable element = new StringElement("foobarbaz");
        long seqNum = 42L;
        ByteBufferPageIO io = newEmptyPageIO();
        io.write(element.serialize(), seqNum);

        byte[] initialState = io.dump();
        newPageIO(initialState.length, initialState);
        io.open(1L, 1);
    }

    @RunWith(Parameterized.class)
    public static class SingleInvalidElementTest {

        private static final List<BufferGenerator> singleGenerators = Arrays.asList(
            // invalid length
            () -> {
                Queueable element = new StringElement("foobarbaz");
                ByteBufferPageIO io = newEmptyPageIO();
                byte[] bytes = element.serialize();
                io.write(bytes, 1L, 514, io.checksum(bytes));
                return io.dump();
            },

            // invalid checksum
            () -> {
                Queueable element = new StringElement("foobarbaz");
                ByteBufferPageIO io = newEmptyPageIO();
                byte[] bytes = element.serialize();
                io.write(bytes, 1L, bytes.length, 77);
                return io.dump();
            },

            // invalid payload
            () -> {
                Queueable element = new StringElement("foobarbaz");
                ByteBufferPageIO io = newEmptyPageIO();
                byte[] bytes = element.serialize();
                int checksum = io.checksum(bytes);
                bytes[1] = 0x01;
                io.write(bytes, 1L, bytes.length, checksum);
                return io.dump();
            }
        );

        @Parameters
        public static Collection<byte[]> singleElementParameters() {
            return singleGenerators.stream().map(g -> uncheck(g::generate)).collect(Collectors.toList());
        }

        @Parameter
        public byte[] singleElementParameter;

        @Test
        public void openInvalidSingleElement() throws IOException {
            // none of these should generate an exception with open()

            ByteBufferPageIO io = newPageIO(singleElementParameter.length, singleElementParameter);
            io.open(1L, 1);

            assertThat(io.getElementCount(), is(equalTo(1)));
            assertThat(io.getMinSeqNum(), is(equalTo(1L)));
        }

        @Test
        public void recoverInvalidSingleElement() throws IOException {
            for (BufferGenerator generator : singleGenerators) {
                byte[] bytes = generator.generate();
                ByteBufferPageIO io = newPageIO(bytes.length, bytes);
                io.recover();

                assertThat(io.getElementCount(), is(equalTo(0)));
            }
        }
    }

    @RunWith(Parameterized.class)
    public static class DoubleInvalidElementTest {

        private static final List<BufferGenerator> doubleGenerators = Arrays.asList(
            // invalid length
            () -> {
                Queueable element = new StringElement("foobarbaz");
                ByteBufferPageIO io = newEmptyPageIO();
                byte[] bytes = element.serialize();
                io.write(bytes.clone(), 1L, bytes.length, io.checksum(bytes));
                io.write(bytes, 2L, 514, io.checksum(bytes));
                return io.dump();
            },

            // invalid checksum
            () -> {
                Queueable element = new StringElement("foobarbaz");
                ByteBufferPageIO io = newEmptyPageIO();
                byte[] bytes = element.serialize();
                io.write(bytes.clone(), 1L, bytes.length, io.checksum(bytes));
                io.write(bytes, 2L, bytes.length, 77);
                return io.dump();
            },

            // invalid payload
            () -> {
                Queueable element = new StringElement("foobarbaz");
                ByteBufferPageIO io = newEmptyPageIO();
                byte[] bytes = element.serialize();
                int checksum = io.checksum(bytes);
                io.write(bytes.clone(), 1L, bytes.length, io.checksum(bytes));
                bytes[1] = 0x01;
                io.write(bytes, 2L, bytes.length, checksum);
                return io.dump();
            }
        );

        @Parameters
        public static Collection<byte[]> doubleElementParameters() {
            return doubleGenerators.stream().map(g -> uncheck(g::generate)).collect(Collectors.toList());
        }

        @Parameter
        public byte[] doubleElementParameter;

        @Test
        public void openInvalidDoubleElement() throws IOException {
            // none of these will generate an exception with open()

            ByteBufferPageIO io = newPageIO(doubleElementParameter.length, doubleElementParameter);
            io.open(1L, 2);

            assertThat(io.getElementCount(), is(equalTo(2)));
            assertThat(io.getMinSeqNum(), is(equalTo(1L)));
        }

        @Test
        public void recoverInvalidDoubleElement() throws IOException {
            ByteBufferPageIO io = newPageIO(doubleElementParameter.length, doubleElementParameter);
            io.recover();

            assertThat(io.getElementCount(), is(equalTo(1)));
         }
    }

    @Test(expected = AbstractByteBufferPageIO.PageIOInvalidElementException.class)
    public void openInvalidDeqNumDoubleElement() throws IOException {
        Queueable element = new StringElement("foobarbaz");
        ByteBufferPageIO io = newEmptyPageIO();
        byte[] bytes = element.serialize();
        io.write(bytes.clone(), 1L, bytes.length, io.checksum(bytes));
        io.write(bytes, 3L, bytes.length, io.checksum(bytes));

        io = newPageIO(io.dump().length, io.dump());
        io.open(1L, 2);
    }

    @Test
    public void recoverInvalidDeqNumDoubleElement() throws IOException {
        Queueable element = new StringElement("foobarbaz");
        ByteBufferPageIO io = newEmptyPageIO();
        byte[] bytes = element.serialize();
        io.write(bytes.clone(), 1L, bytes.length, io.checksum(bytes));
        io.write(bytes, 3L, bytes.length, io.checksum(bytes));

        io = newPageIO(io.dump().length, io.dump());
        io.recover();

        assertThat(io.getElementCount(), is(equalTo(1)));
    }

    @Test
    public void writeRead() throws IOException {
        long seqNum = 42L;
        Queueable element = buildStringElement("foobarbaz");
        ByteBufferPageIO io = newEmptyPageIO();
        io.write(element.serialize(), seqNum);
        SequencedList<byte[]> result = io.read(seqNum, 1);
        assertThat(result.getElements().size(), is(equalTo(1)));
        Queueable readElement = StringElement.deserialize(result.getElements().get(0));
        assertThat(result.getSeqNums().get(0), is(equalTo(seqNum)));
        assertThat(readElement.toString(), is(equalTo(element.toString())));
    }

    @Test
    public void writeReadMulti() throws IOException {
        Queueable element1 = buildStringElement("foo");
        Queueable element2 = buildStringElement("bar");
        Queueable element3 = buildStringElement("baz");
        Queueable element4 = buildStringElement("quux");
        ByteBufferPageIO io = newEmptyPageIO();
        io.write(element1.serialize(), 40L);
        io.write(element2.serialize(), 41L);
        io.write(element3.serialize(), 42L);
        io.write(element4.serialize(), 43L);
        int batchSize = 11;
        SequencedList<byte[]> result = io.read(40L, batchSize);
        assertThat(result.getElements().size(), is(equalTo(4)));

        assertThat(result.getSeqNums().get(0), is(equalTo(40L)));
        assertThat(result.getSeqNums().get(1), is(equalTo(41L)));
        assertThat(result.getSeqNums().get(2), is(equalTo(42L)));
        assertThat(result.getSeqNums().get(3), is(equalTo(43L)));

        assertThat(StringElement.deserialize(result.getElements().get(0)).toString(), is(equalTo(element1.toString())));
        assertThat(StringElement.deserialize(result.getElements().get(1)).toString(), is(equalTo(element2.toString())));
        assertThat(StringElement.deserialize(result.getElements().get(2)).toString(), is(equalTo(element3.toString())));
        assertThat(StringElement.deserialize(result.getElements().get(3)).toString(), is(equalTo(element4.toString())));
    }
}
package org.logstash.translog;

import org.logstash.previous_ackedqueue.Page;
import org.logstash.previous_ackedqueue.PageState;

import java.io.IOException;

public class Translog {


    public static void writeRecordNoSize(BufferedChecksumStreamOutput out, Translog.Record record) throws IOException {
        out.resetDigest();
        Translog.Record.writeType(record, out);
        long checksum = out.getChecksum();
        out.writeInt((int) checksum);
    }

    public static class ActivePages implements Record {
        public static final int SERIALIZATION_FORMAT = 1;

        private final long[] activePages;

        public ActivePages(StreamInput in) throws IOException {
            final int format = in.readVInt(); // SERIALIZATION_FORMAT
            assert format == SERIALIZATION_FORMAT : "format was: " + format;
            int length = in.readVInt();
            activePages = new long[length];
            for (int i = 0; i < length; i++) {
                activePages[i] = in.readLong();
            }
        }

        public ActivePages(Page[] actives) {
            int length = actives.length;
            this.activePages = new long[length];
            for (int i = 0; i < length; i++) {
                activePages[i] = actives[i].getIndex();
            }
        }

        public Type opType() {
            return Type.ACTIVEPAGES;
        }

        @Override
        public void writeTo(StreamOutput out) throws IOException {
            out.writeVInt(SERIALIZATION_FORMAT);
            out.writeVInt(activePages.length);
            for (long page : activePages) {
                out.writeLong(page);
            }
        }



    }

    public static class ActivePage implements Record {
        public static final int SERIALIZATION_FORMAT = 1;

        private PageState state;
        private long index;

        public ActivePage(StreamInput in) throws IOException {
            index = in.readLong();
            byte[] input = in.readByteArray();
            state = PageState.deserialize(input);
        }

        public ActivePage(Page page) {
            this.index = page.getIndex();
            this.state = page.getPageState();
        }

        public ActivePage(PageState state) {
            this.index = 0L;
            this.state = state;
        }

        public Type opType() {
            return Type.PAGESTATE;
        }

        @Override
        public void writeTo(StreamOutput out) throws IOException {
            out.writeVInt(SERIALIZATION_FORMAT);
            out.writeLong(index);
            out.writeByteArray(state.serialize());
        }
    }

    public interface Record {
        enum Type {
            ACTIVEPAGES((byte) 1),
            PAGESTATE((byte) 2);
            private final byte id;

            Type(byte id) {
                this.id = id;
            }



            public byte id() {
                return this.id;
            }

            public static Type fromId(byte id) {
                switch (id) {
                    case 1:
                        return ACTIVEPAGES;
                    case 2:
                        return PAGESTATE;
                    default:
                        throw new IllegalArgumentException("No type mapped for [" + id + "]");
                }
            }

        }

        Type opType();

        void writeTo(StreamOutput out) throws IOException;

        static Record readType(StreamInput input) throws IOException {
            Translog.Record.Type type = Translog.Record.Type.fromId(input.readByte());
            switch (type) {
                case ACTIVEPAGES:
                    return new Translog.ActivePages(input);
                case PAGESTATE:
                    return new Translog.ActivePage(input);
                default:
                    throw new IOException("No type for [" + type + "]");
            }
        }

        static void writeType(Translog.Record record, StreamOutput output) throws IOException {
            output.writeByte(record.opType().id());
            record.writeTo(output);
        }
    }
}

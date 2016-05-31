package com.logstash;

import java.io.IOException;
import java.math.BigDecimal;
import java.math.BigInteger;
import java.util.Map;
import java.util.HashMap;
import java.security.SecureRandom;
import java.util.Random;

public class SerializeProfileRunner {
    public static class ProExec {

        public Event cached_event;

        public Event eventBuilder() {
            String str1 = Randomizer.nextString();
            String str2 = Randomizer.nextString();
            long num = Randomizer.nextLong();
            BigDecimal bd = Randomizer.nextBigDecimal();
            BigInteger bi = Randomizer.nextBigInteger();
            Timestamp t = new Timestamp(Randomizer.nextEpoch());

            Map data = new HashMap();
            data.put(Randomizer.nextString(), Randomizer.nextInt());
            data.put(Randomizer.nextString(), Randomizer.nextString());
            data.put(Randomizer.nextString(), Randomizer.nextDouble());

            Map meta = new HashMap();
            meta.put(Randomizer.nextString(), str1);

            data.put(Event.METADATA, meta);
            Event event = new Event(data);

            event.setField(ref(), num);
            event.setField(ref(), bd);
            event.setField(ref(), bi);
            event.setField(mref(), str2);
            event.setField(Event.TIMESTAMP, t);
            event.cancel();
            return event;
        }

        public byte[] measureByteSerialize() {
//            return event().byteSerialize();
            return cached_event.byteSerialize();
        }

        public String measureJSONSerialize() {
            String result;
            try {
                result = cached_event.toJson();
            } catch (IOException e) {
                System.err.println(e.getMessage());
                result = e.getMessage();
            }
            return result;
        }

        public void doSetup() {
            cached_event = eventBuilder();
            System.out.println("Do Setup");
        }

        public void doTearDown() {
            System.out.println("Do TearDown");
        }

        private String ref() {
            return "[" + Randomizer.nextString() + "]";
        }

        private String mref() {
            return "[@metadata][" + Randomizer.nextString() + "]";
        }
    }

    public final static class Randomizer {
        private static SecureRandom random = new SecureRandom();
        private static final Random rng = new Random();

        public static String nextString() {
            return nextBigInteger().toString(32);
        }
        public static BigInteger nextBigInteger() {
            return new BigInteger(130, random);
        }
        public static BigDecimal nextBigDecimal() {
            return BigDecimal.valueOf(nextDouble() / 3.0);
        }

        public static double nextDouble() {
            return nextBigInteger().doubleValue();
        }

        public static long nextLong() {
            return nextBigInteger().longValue();
        }

        public static int nextInt() {
            return nextBigInteger().intValue();
        }
        public static long nextEpoch() {
            int ago = rng.nextInt(7 * 24 * 60 * 60 * 1000);
            return System.currentTimeMillis() - ago;
        }
    }

    public static void main(String[] args) {
//        int max = 2;
        int max = 200000000;
        ProExec pe = new ProExec();
        pe.doSetup();

        for (int i = 0; i < max; i++) {
//            System.out.println(pe.measureJSONSerialize());
//            pe.measureJSONSerialize();
            pe.measureByteSerialize();
        }
    }
}

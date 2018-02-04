package org.logstash.elastiqueue;

import java.io.InputStream;
import java.util.Scanner;

public class Util {
    public static String inputStringToStream(InputStream stream) {
        try (Scanner s = new Scanner(stream)) {
            return s.useDelimiter("\\A").hasNext() ? s.next() : null;
        }
    }
}

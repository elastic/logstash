package com.logstash;


import com.logstash.bivalues.BiValue;
import com.logstash.bivalues.BiValues;
import java.util.List;
import java.util.Map;

public class Javafier {
    private static final String ERR_TEMPLATE = "Missing Ruby class handling for full class name=%s, simple name=%s";
    /*
    Javafier.deep() is called by getField.
    If Valuefier did its job when converting the raw Ruby Objects into
    either ConvertedMap, ConvertedArray or BiValue, then these objects
    are the only types needing Javafying.
     */
    private Javafier(){}

    public static Object deep(Object o) {
        if (o instanceof BiValue) {
            return ((BiValue)o).javaValue();
        } else if(o instanceof Map || o instanceof List) {
            return o;
        } else {
            try {
                return BiValues.newBiValue(o).javaValue();
            } catch (IllegalArgumentException e) {
                Class cls = o.getClass();
                throw new IllegalArgumentException(String.format(ERR_TEMPLATE, cls.getName(), cls.getSimpleName()));
            }
        }
    }
}


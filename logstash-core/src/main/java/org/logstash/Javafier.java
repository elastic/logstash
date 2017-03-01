package org.logstash;


import org.logstash.bivalues.BiValue;
import org.logstash.bivalues.BiValues;

public class Javafier {
    private static final String ERR_TEMPLATE = "Missing Ruby class handling for full class name=%s, simple name=%s";
    /*
    Javafier.deep() is called by getField.
    When any value is added to the Event it should pass through Valuefier.convert.
    deep(Object o) is the mechanism to pluck the Java value from a BiValue or convert a
    ConvertedList and ConvertedMap back to ArrayList or HashMap.
     */
    private Javafier(){}

    public static Object deep(Object o) {
        if (o instanceof BiValue) {
            return ((BiValue)o).javaValue();
        } else if(o instanceof ConvertedMap) {
            return ((ConvertedMap) o).unconvert();
        }  else if(o instanceof ConvertedList) {
            return ((ConvertedList) o).unconvert();
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


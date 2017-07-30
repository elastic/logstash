package org.logstash;


import org.jruby.RubyString;
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
        if (o instanceof RubyString) {
            return o.toString();
        }
        if (o instanceof String) {
            return o;
        }
        if (o instanceof BiValue) {
            return ((BiValue)o).javaValue();
        } else if(o instanceof ConvertedMap) {
            return ((ConvertedMap) o).unconvert();
        }  else if(o instanceof ConvertedList) {
            return ((ConvertedList) o).unconvert();
        } else {
            return fallback(o);
        }
    }

    /**
     * Cold path of {@link Javafier#deep(Object)}.
     * We assume that we never get an input that is neither {@link ConvertedMap}, {@link ConvertedList}
     * nor {@link BiValue}, but fallback to attempting to create a {@link BiValue} from the input
     * before converting to a Java type.
     * @param o Know to not be an expected type in {@link Javafier#deep(Object)}.
     * @return Input converted to Java type
     */
    private static Object fallback(final Object o) {
        try {
            return BiValues.newBiValue(o).javaValue();
        } catch (IllegalArgumentException e) {
            Class cls = o.getClass();
            throw new IllegalArgumentException(String.format(ERR_TEMPLATE, cls.getName(), cls.getSimpleName()));
        }
    }
}


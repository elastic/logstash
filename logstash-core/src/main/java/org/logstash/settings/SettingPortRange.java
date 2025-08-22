package org.logstash.settings;

import java.util.function.Predicate;

@SuppressWarnings({"rawtypes", "unchecked"})
public class SettingPortRange extends Coercible<Range<Integer>> {

    private static final Range<Integer> VALID_PORT_RANGE = new Range<>(1, 65535);
    public static final String PORT_SEPARATOR = "-";

    public SettingPortRange(String name, Range<Integer> defaultValue) {
        super(name, defaultValue, true, SettingPortRange::isValid);
    }

    public static boolean isValid(Range<Integer> range) {
        return VALID_PORT_RANGE.contains(range);
    }

    // TODO cover with tests
    @Override
    public Range<Integer> coerce(Object obj) {
        if (obj instanceof Range) {
            return (Range) obj;
        }

        if (obj instanceof Integer) {
            Integer val = (Integer) obj;
            return new Range<>(val, val);
        }

        if (obj instanceof Long) {
            Long val = (Long) obj;
            return new Range<>(val.intValue(), val.intValue());
        }

        if (obj instanceof String) {
            String val = (String) obj;
            String[] parts = val.split(PORT_SEPARATOR);
            String firstStr = parts[0];
            String lastStr;
            if (parts.length == 1) {
                lastStr = firstStr;
            } else {
                lastStr = parts[1];
            }
            try {
                int first = Integer.parseInt(firstStr);
                int last = Integer.parseInt(lastStr);
                return new Range<>(first, last);
            } catch(NumberFormatException e) {
                throw new IllegalArgumentException("Could not coerce [" + obj + "](type: " + obj.getClass() + ") into a port range");
            }
        }
        throw new IllegalArgumentException("Could not coerce [" + obj + "](type: " + obj.getClass() + ") into a port range");
    }

    @Override
    public void validate(Range<Integer> value) throws IllegalArgumentException {
        if (!isValid(value)) {
            final String msg = String.format("Invalid value \"{}: {}}\", valid options are within the range of {}-{}",
                    getName(), value, VALID_PORT_RANGE, VALID_PORT_RANGE.getFirst(), VALID_PORT_RANGE.getLast());

            throw new IllegalArgumentException(msg);
        }
    }
}

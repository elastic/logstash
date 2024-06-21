package org.logstash.settings;

public class BooleanSetting extends Coercible<Boolean> {

    public BooleanSetting(String name, boolean defaultValue) {
        super(name, defaultValue, true, noValidator());
    }

    @Override
    public Boolean coerce(Object obj) {
        if (obj instanceof String) {
            switch((String) obj) {
                case "true": return true;
                case "false": return false;
                default: throw new IllegalArgumentException("could not coerce " + value() + " into a boolean");
            }
        }
        if (obj instanceof Boolean) {
            return (Boolean) obj;
        }
        throw new IllegalArgumentException("could not coerce " + value() + " into a boolean");
    }
}
package org.logstash.settings;

public class Boolean extends Coercible<java.lang.Boolean> {

    public Boolean(String name, boolean defaultValue) {
        super(name, defaultValue, true, noValidator());
    }

    @Override
    public java.lang.Boolean coerce(Object obj) {
        if (obj instanceof String) {
            switch((String) obj) {
                case "true": return true;
                case "false": return false;
                default: throw new IllegalArgumentException("could not coerce " + value() + " into a boolean");
            }
        }
        if (obj instanceof java.lang.Boolean) {
            return (java.lang.Boolean) obj;
        }
        throw new IllegalArgumentException("could not coerce " + value() + " into a boolean");
    }
}
package org.logstash;

import org.apache.logging.log4j.core.AbstractLifeCycle;
import org.apache.logging.log4j.core.Filter;
import org.apache.logging.log4j.core.Layout;
import org.apache.logging.log4j.core.config.Property;
import org.apache.logging.log4j.core.filter.AbstractFilterable;

import java.io.Serializable;

public class JavaClassWithInitialize
//        extends AbstractLifeCycle
        extends AbstractFilterable
{
    private String name;

//    protected JavaClassWithInitialize(String name) {
//        this.name = name;
//    }
//
//    protected JavaClassWithInitialize(String name, String surname) {
//        this.name = name + surname;
//    }
//
//    protected JavaClassWithInitialize(String name, String surname, boolean collapse) {
//        this.name = name + surname;
//    }

//    @Deprecated
    protected JavaClassWithInitialize(final String name, final Filter filter, final Layout<? extends Serializable> layout) {
        this(name, filter, layout, true, Property.EMPTY_ARRAY);
    }

//    /** @deprecated */
//    @Deprecated
//    protected JavaClassWithInitialize(final String name, final Filter filter, final Layout<? extends Serializable> layout, final boolean ignoreExceptions) {
//        this(name, filter, layout, ignoreExceptions, Property.EMPTY_ARRAY);
//    }

    protected JavaClassWithInitialize(final String name, final Filter filter, final Layout<? extends Serializable> layout, final boolean ignoreExceptions, final Property[] properties) {
        this.name = name;
    }

    @Override
    public void initialize() {
        this.name = "Name added";
    }
}

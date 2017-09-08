package org.logstash.config.ir.expression;

import org.logstash.common.SourceWithMetadata;
import org.logstash.config.ir.BaseSourceComponent;
import org.logstash.config.ir.HashableWithSource;

/*
 * [foo] == "foostr" eAnd [bar] > 10
 * eAnd(eEq(eventValueExpr("foo"), value("foostr")), eEq(eEventValue("bar"), value(10)))
 *
 * if [foo]
 * notnull(eEventValue("foo"))
 * Created by andrewvc on 9/6/16.
 */
public abstract class Expression extends BaseSourceComponent implements HashableWithSource {

    public Expression(SourceWithMetadata meta) {
        super(meta);
    }

    @Override
    public String toString(int indent) {
        return toString();
    }

    @Override
    public String toString() {
        return toRubyString();
    }

    public abstract String toRubyString();

    public String hashSource() {
        return toRubyString();
    }
}

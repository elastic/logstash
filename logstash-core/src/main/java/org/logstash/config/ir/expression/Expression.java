package org.logstash.config.ir.expression;

import org.logstash.config.ir.SourceComponent;
import org.logstash.config.ir.SourceMetadata;

/**
 * [foo] == "foostr" eAnd [bar] > 10
 * eAnd(eEq(eventValueExpr("foo"), value("foostr")), eEq(eEventValue("bar"), value(10)))
 *
 * if [foo]
 * notnull(eEventValue("foo"))
 * Created by andrewvc on 9/6/16.
 */
public abstract class Expression extends SourceComponent {
    public Expression(SourceMetadata meta) {
        super(meta);
    }
}

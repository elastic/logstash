package org.logstash.config.ir.expression;

import org.jruby.RubyInstanceConfig;
import org.jruby.embed.AttributeName;
import org.jruby.embed.ScriptingContainer;
import org.logstash.config.ir.Hashable;
import org.logstash.config.ir.BaseSourceComponent;
import org.logstash.config.ir.SourceMetadata;

/*
 * [foo] == "foostr" eAnd [bar] > 10
 * eAnd(eEq(eventValueExpr("foo"), value("foostr")), eEq(eEventValue("bar"), value(10)))
 *
 * if [foo]
 * notnull(eEventValue("foo"))
 * Created by andrewvc on 9/6/16.
 */
public abstract class Expression extends BaseSourceComponent implements Hashable {
    private Object compiled;
    private ScriptingContainer container;

    public Expression(SourceMetadata meta) {
        super(meta);
    }

    public boolean eval() {
        return true;
    }

    public void compile() {
        container = new ScriptingContainer();
        container.setCompileMode(RubyInstanceConfig.CompileMode.JIT);
        container.setAttribute(AttributeName.SHARING_VARIABLES, false);
        container.runScriptlet("def start(event)\n" + this.toString() + "\nend");
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
}
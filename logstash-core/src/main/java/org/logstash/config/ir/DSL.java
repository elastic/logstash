package org.logstash.config.ir;

import org.logstash.config.ir.expression.*;
import org.logstash.config.ir.imperative.*;

import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

import static org.logstash.config.ir.expression.BinaryBooleanExpression.Operator.*;
import static org.logstash.config.ir.expression.UnaryBooleanExpression.Operator.*;

/**
 * Created by andrewvc on 9/15/16.
 */
public class DSL {
    public static EventValueExpression eEventValue(SourceMetadata meta, String fieldName) {
        return new EventValueExpression(meta, fieldName);
    }

    public static EventValueExpression eEventValue(String fieldName) {
        return eEventValue(new SourceMetadata(), fieldName);
    }

    public static ValueExpression eValue(SourceMetadata meta, Object value) throws InvalidIRException {
        return new ValueExpression(meta, value);
    }

    public static ValueExpression eValue(Object value) throws InvalidIRException {
        return eValue(new SourceMetadata(), value);
    }

    public static ValueExpression eRegex(SourceMetadata meta, String pattern) throws InvalidIRException {
       return new RegexValueExpression(meta, pattern);
    }

    public static ValueExpression eRegex(String pattern) throws InvalidIRException {
        return eRegex(new SourceMetadata(), pattern);
    }

    public static ValueExpression eValue(long value) {
        try {
            return eValue(new SourceMetadata(), value);
        } catch (InvalidIRException e) {
            e.printStackTrace(); // Can't happen with an int
            return null;
        }
    }

    public static ValueExpression eValue(double value) {
        try {
            return eValue(new SourceMetadata(), value);
        } catch (InvalidIRException e) {
            e.printStackTrace(); // Can't happen with an int
            return null;
        }
    }

    public static BinaryBooleanExpression eBinaryBoolean(SourceMetadata meta, BinaryBooleanExpression.Operator operator, Expression left, Expression right) throws InvalidIRException {
        return new BinaryBooleanExpression(meta, operator, left, right);
    }

    public static BinaryBooleanExpression eBinaryBoolean(BinaryBooleanExpression.Operator operator, Expression left, Expression right) throws InvalidIRException {
        return eBinaryBoolean(new SourceMetadata(), operator, left, right);
    }

    public static UnaryBooleanExpression eBinaryBoolean(UnaryBooleanExpression.Operator operator, Expression expr) {
        return new UnaryBooleanExpression(new SourceMetadata(), operator, expr);
    }

    public static BinaryBooleanExpression eGt(Expression left, Expression right) throws InvalidIRException {
        return eBinaryBoolean(GT, left, right);
    }

    public static BinaryBooleanExpression eGte(Expression left, Expression right) throws InvalidIRException {
        return eBinaryBoolean(GTE, left, right);
    }

    public static BinaryBooleanExpression eLt(Expression left, Expression right) throws InvalidIRException {
        return eBinaryBoolean(LT, left, right);
    }

    public static BinaryBooleanExpression eLte(Expression left, Expression right) throws InvalidIRException {
        return eBinaryBoolean(LTE, left, right);
    }

    public static BinaryBooleanExpression eEq(Expression left, Expression right) throws InvalidIRException {
        return eBinaryBoolean(EQ, left, right);
    }

    public static BinaryBooleanExpression eAnd(Expression left, Expression right) throws InvalidIRException {
        return eBinaryBoolean(AND, left, right);
    }

    public static BinaryBooleanExpression eOr(Expression left, Expression right) throws InvalidIRException {
        return eBinaryBoolean(OR, left, right);
    }

    public static BinaryBooleanExpression eRegexEq(Expression left, ValueExpression right) throws InvalidIRException {
        return eBinaryBoolean(REGEXPEQ, left, right);
    }

    public static BinaryBooleanExpression eRegexNeq(Expression left, ValueExpression right) throws InvalidIRException {
        return eBinaryBoolean(REGEXPNEQ, left, right);
    }

    public static BinaryBooleanExpression eNeq(Expression left, Expression right) throws InvalidIRException {
        return eBinaryBoolean(NEQ, left, right);
    }

    public static BinaryBooleanExpression eIn(Expression left, Expression right) throws InvalidIRException {
        return eBinaryBoolean(IN, left, right);
    }

    public static UnaryBooleanExpression eNot(Expression expr) {
        return eBinaryBoolean(NOT, expr);
    }

    public static UnaryBooleanExpression eNotNull(Expression expr) {
        return eBinaryBoolean(NOTNULL, expr);
    }

    public static UnaryBooleanExpression eIsNull(Expression expr) {
        return eBinaryBoolean(ISNULL, expr);
    }

    public static Statement iCompose(SourceMetadata meta, Statement... statements) throws InvalidIRException {
        if (statements.length == 0 ) {
            return new NoopStatement(meta);
        } else if (statements.length == 1 ) {
            return statements[0];
        } else {
            return new ComposedStatement(meta, Arrays.asList(statements));
        }
    }

    public static NoopStatement noop(SourceMetadata meta) {
        return new NoopStatement(meta);
    }

    public static NoopStatement noop() {
        return new NoopStatement(new SourceMetadata());
    }

    public static Statement iCompose(Statement... statements) throws InvalidIRException {
        return iCompose(new SourceMetadata(), statements);
    }

    public static PluginStatement iPlugin(SourceMetadata meta, String pluginName, Map<String, Object> pluginArguments) {
        return new PluginStatement(meta, pluginName, pluginArguments);
    }

    public static PluginStatement iPlugin(String pluginName, Map<String, Object> pluginArguments) {
        return new PluginStatement(new SourceMetadata(), pluginName, pluginArguments);
    }

    public static PluginStatement iPlugin(String pluginName, MapBuilder<String, Object> argBuilder) {
        return iPlugin(pluginName, argBuilder.build());
    }


    public static PluginStatement iPlugin(String pluginName) {
        return iPlugin(pluginName, pargs());
    }

    public static IfStatement iIf(SourceMetadata meta,
                                  BooleanExpression condition,
                                  Statement ifTrue,
                                  Statement ifFalse) throws InvalidIRException {
        return new IfStatement(meta, condition, ifTrue, ifFalse);
    }

    public static IfStatement iIf(BooleanExpression condition,
                                  Statement ifTrue,
                                  Statement ifFalse) throws InvalidIRException {
        return iIf(new SourceMetadata(), condition, ifTrue, ifFalse);
    }

    public static IfStatement iIf(BooleanExpression condition,
                                  Statement ifTrue) throws InvalidIRException {
        return iIf(new SourceMetadata(), condition, ifTrue, noop());
    }


    public static class MapBuilder<K,V> {
        private final HashMap<K, V> map;

        public MapBuilder() {
            this.map = new HashMap<>();
        }

        public MapBuilder<K, V> put(K k, V v) {
            map.put(k, v);
            return this;
        }

        public Map<K, V> build() {
            return map;
        }
    }

    static <K,V> MapBuilder<K,V> mapBuilder() {
        return new MapBuilder<>();
    }

    public static MapBuilder<String, Object> argumentBuilder() {
        return mapBuilder();
    }

    public static MapBuilder<String, Object> pargs() {
        return argumentBuilder();
    }
}

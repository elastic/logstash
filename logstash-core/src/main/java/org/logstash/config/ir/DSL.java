package org.logstash.config.ir;

import org.apache.logging.log4j.core.config.plugins.Plugin;
import org.logstash.config.ir.expression.*;
import org.logstash.config.ir.expression.binary.*;
import org.logstash.config.ir.expression.unary.Not;
import org.logstash.config.ir.expression.unary.Truthy;
import org.logstash.config.ir.graph.Graph;
import org.logstash.config.ir.graph.IfVertex;
import org.logstash.config.ir.graph.PluginVertex;
import org.logstash.config.ir.imperative.*;

import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

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

    public static Gt eGt(SourceMetadata meta, Expression left, Expression right) throws InvalidIRException {
        return new Gt(meta, left, right);
    }

    public static Gt eGt(Expression left, Expression right) throws InvalidIRException {
        return new Gt(null, left, right);
    }

    public static Gte eGte(SourceMetadata meta, Expression left, Expression right) throws InvalidIRException {
        return new Gte(meta, left, right);
    }

    public static Gte eGte(Expression left, Expression right) throws InvalidIRException {
        return new Gte(null, left, right);
    }

    public static Lt eLt(SourceMetadata meta, Expression left, Expression right) throws InvalidIRException {
        return new Lt(meta, left, right);
    }

    public static Lt eLt(Expression left, Expression right) throws InvalidIRException {
        return new Lt(null, left, right);
    }

    public static Lte eLte(SourceMetadata meta, Expression left, Expression right) throws InvalidIRException {
        return new Lte(meta, left, right);
    }
    public static Lte eLte(Expression left, Expression right) throws InvalidIRException {
        return new Lte(null, left, right);
    }

    public static Eq eEq(SourceMetadata meta, Expression left, Expression right) throws InvalidIRException {
        return new Eq(meta, left, right);
    }

    public static Eq eEq(Expression left, Expression right) throws InvalidIRException {
        return new Eq(null, left, right);
    }

    public static And eAnd(SourceMetadata meta, Expression left, Expression right) throws InvalidIRException {
        return new And(meta, left, right);
    }

    public static And eAnd(Expression left, Expression right) throws InvalidIRException {
        return new And(null, left, right);
    }

    public static Or eOr(SourceMetadata meta, Expression left, Expression right) throws InvalidIRException {
        return new Or(meta, left, right);
    }

    public static Or eOr(Expression left, Expression right) throws InvalidIRException {
        return new Or(null, left, right);
    }

    public static RegexEq eRegexEq(SourceMetadata meta, Expression left, ValueExpression right) throws InvalidIRException {
        return new RegexEq(meta, left, right);
    }

    public static RegexEq eRegexEq(Expression left, ValueExpression right) throws InvalidIRException {
        return new RegexEq(null, left, right);
    }

    public static Expression eRegexNeq(SourceMetadata meta, Expression left, ValueExpression right) throws InvalidIRException {
        return eNot(eRegexEq(meta, left, right));
    }

    public static Expression eRegexNeq(Expression left, ValueExpression right) throws InvalidIRException {
        return eNot(eRegexEq(left, right));
    }

    public static Neq eNeq(SourceMetadata meta, Expression left, Expression right) throws InvalidIRException {
        return new Neq(meta, left, right);
    }
    public static Neq eNeq(Expression left, Expression right) throws InvalidIRException {
        return new Neq(null, left, right);
    }

    public static In eIn(SourceMetadata meta, Expression left, Expression right) throws InvalidIRException {
        return new In(meta, left, right);
    }

    public static In eIn(Expression left, Expression right) throws InvalidIRException {
        return new In(null, left, right);
    }

    public static Not eNot(SourceMetadata meta, Expression expr) throws InvalidIRException {
        return new Not(meta, expr);
    }

    public static Not eNot(Expression expr) throws InvalidIRException {
        return new Not(null, expr);
    }

    public static BooleanExpression eTruthy(SourceMetadata meta, Expression expr) throws InvalidIRException {
        if (expr instanceof BooleanExpression) {
            return (BooleanExpression) expr;
        }
        return new Truthy(meta, expr);
    }
    public static BooleanExpression eTruthy(Expression expr) throws InvalidIRException {
        return eTruthy(null, expr);
    }

    public static Statement iCompose(ComposedStatement.IFactory factory, SourceMetadata meta, Statement... statements) throws InvalidIRException {
        if (statements.length == 0 ) {
            return new NoopStatement(meta);
        } else if (statements.length == 1 ) {
            return statements[0];
        } else {
            return factory.make(meta, Arrays.asList(statements));
        }
    }

    public static Statement iComposeSequence(SourceMetadata meta, Statement... statements) throws InvalidIRException {
        return iCompose(ComposedSequenceStatement::new, meta, statements);
    }

    public static Statement iComposeSequence(Statement... statements) throws InvalidIRException {
        return iComposeSequence(null, statements);
    }

    public static Statement iComposeParallel(SourceMetadata meta, Statement... statements) throws InvalidIRException {
        return iCompose(ComposedParallelStatement::new, meta, statements);
    }

    public static Statement iComposeParallel(Statement... statements) throws InvalidIRException {
        return iComposeParallel(null, statements);
    }

    public static NoopStatement noop(SourceMetadata meta) {
        return new NoopStatement(meta);
    }

    public static NoopStatement noop() {
        return new NoopStatement(new SourceMetadata());
    }

    public static PluginStatement iPlugin(SourceMetadata meta, PluginDefinition.Type pluginType,  String pluginName, Map<String, Object> pluginArguments) {
        return new PluginStatement(meta, new PluginDefinition(pluginType, pluginName, pluginArguments));
    }

    public static PluginStatement iPlugin(PluginDefinition.Type type, String pluginName, Map<String, Object> pluginArguments) {
        return iPlugin(new SourceMetadata(), type, pluginName, pluginArguments);
    }

    public static PluginStatement iPlugin(PluginDefinition.Type type, String pluginName, MapBuilder<String, Object> argBuilder) {
        return iPlugin(type, pluginName, argBuilder.build());
    }

    public static PluginStatement iPlugin(PluginDefinition.Type type, String pluginName, String id) {
        return iPlugin(type, pluginName, argumentBuilder().put("id", id).build());
    }

    public static PluginStatement iPlugin(PluginDefinition.Type type, String pluginName) {
        return iPlugin(type, pluginName, pargs());
    }

    public static IfStatement iIf(SourceMetadata meta,
                                  Expression condition,
                                  Statement ifTrue,
                                  Statement ifFalse) throws InvalidIRException {
        BooleanExpression booleanExpression = eTruthy(meta, condition);
        return new IfStatement(meta, booleanExpression, ifTrue, ifFalse);
    }

    public static IfStatement iIf(Expression condition,
                                  Statement ifTrue,
                                  Statement ifFalse) throws InvalidIRException {
        return iIf(new SourceMetadata(), condition, ifTrue, ifFalse);
    }

    public static IfStatement iIf(Expression condition,
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

    public static Graph graph() {
        return new Graph();
    }

    public static PluginVertex gPlugin(SourceMetadata sourceMetadata, PluginDefinition.Type pluginType, String pluginName, Map<String, Object> pluginArgs) {
       return new PluginVertex(sourceMetadata, new PluginDefinition(pluginType, pluginName, pluginArgs));
    }

    public static PluginVertex gPlugin(PluginDefinition.Type type, String pluginName, Map<String, Object> pluginArgs) {
        return gPlugin(new SourceMetadata(), type, pluginName, pluginArgs);
    }

    public static PluginVertex gPlugin(PluginDefinition.Type type, String pluginName, String id) {
        return gPlugin(type, pluginName, argumentBuilder().put("id", id).build());
    }

    public static PluginVertex gPlugin(PluginDefinition.Type type, String pluginName) {
        return gPlugin(new SourceMetadata(), type, pluginName, new HashMap<>());
    }


    public static IfVertex gIf(SourceMetadata meta, BooleanExpression expression) {
       return new IfVertex(meta, expression);
    }

    public static IfVertex gIf(BooleanExpression expression) {
       return new IfVertex(new SourceMetadata(), expression);
    }
}

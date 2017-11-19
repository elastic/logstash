package org.logstash.config.ir;

import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import org.logstash.common.SourceWithMetadata;
import org.logstash.config.ir.expression.BooleanExpression;
import org.logstash.config.ir.expression.EventValueExpression;
import org.logstash.config.ir.expression.Expression;
import org.logstash.config.ir.expression.RegexValueExpression;
import org.logstash.config.ir.expression.ValueExpression;
import org.logstash.config.ir.expression.binary.And;
import org.logstash.config.ir.expression.binary.Eq;
import org.logstash.config.ir.expression.binary.Gt;
import org.logstash.config.ir.expression.binary.Gte;
import org.logstash.config.ir.expression.binary.In;
import org.logstash.config.ir.expression.binary.Lt;
import org.logstash.config.ir.expression.binary.Lte;
import org.logstash.config.ir.expression.binary.Neq;
import org.logstash.config.ir.expression.binary.Or;
import org.logstash.config.ir.expression.binary.RegexEq;
import org.logstash.config.ir.expression.unary.Not;
import org.logstash.config.ir.expression.unary.Truthy;
import org.logstash.config.ir.graph.Graph;
import org.logstash.config.ir.graph.IfVertex;
import org.logstash.config.ir.graph.PluginVertex;
import org.logstash.config.ir.imperative.ComposedParallelStatement;
import org.logstash.config.ir.imperative.ComposedSequenceStatement;
import org.logstash.config.ir.imperative.ComposedStatement;
import org.logstash.config.ir.imperative.IfStatement;
import org.logstash.config.ir.imperative.NoopStatement;
import org.logstash.config.ir.imperative.PluginStatement;
import org.logstash.config.ir.imperative.Statement;

/**
 * Created by andrewvc on 9/15/16.
 */
public class DSL {
    public static EventValueExpression eEventValue(SourceWithMetadata meta, String fieldName) {
        return new EventValueExpression(meta, fieldName);
    }

    public static EventValueExpression eEventValue(String fieldName) {
        return eEventValue(null, fieldName);
    }

    public static ValueExpression eValue(SourceWithMetadata meta, Object value) throws InvalidIRException {
        return new ValueExpression(meta, value);
    }

    public static ValueExpression eValue(Object value) throws InvalidIRException {
        return eValue(null, value);
    }

    public static ValueExpression eRegex(SourceWithMetadata meta, String pattern) throws InvalidIRException {
       return new RegexValueExpression(meta, pattern);
    }

    public static ValueExpression eRegex(String pattern) throws InvalidIRException {
        return eRegex(null, pattern);
    }

    public static ValueExpression eValue(long value) {
        try {
            return eValue(null, value);
        } catch (InvalidIRException e) {
            e.printStackTrace(); // Can't happen with an int
            return null;
        }
    }

    public static ValueExpression eValue(double value) {
        try {
            return eValue(null, value);
        } catch (InvalidIRException e) {
            e.printStackTrace(); // Can't happen with an int
            return null;
        }
    }

    public static Gt eGt(SourceWithMetadata meta, Expression left, Expression right) {
        return new Gt(meta, left, right);
    }

    public static Gt eGt(Expression left, Expression right) {
        return new Gt(null, left, right);
    }

    public static Gte eGte(SourceWithMetadata meta, Expression left, Expression right) {
        return new Gte(meta, left, right);
    }

    public static Gte eGte(Expression left, Expression right) {
        return new Gte(null, left, right);
    }

    public static Lt eLt(SourceWithMetadata meta, Expression left, Expression right) {
        return new Lt(meta, left, right);
    }

    public static Lt eLt(Expression left, Expression right) {
        return new Lt(null, left, right);
    }

    public static Lte eLte(SourceWithMetadata meta, Expression left, Expression right) {
        return new Lte(meta, left, right);
    }
    public static Lte eLte(Expression left, Expression right) {
        return new Lte(null, left, right);
    }

    public static Eq eEq(SourceWithMetadata meta, Expression left, Expression right) {
        return new Eq(meta, left, right);
    }

    public static Eq eEq(Expression left, Expression right) {
        return new Eq(null, left, right);
    }

    public static And eAnd(SourceWithMetadata meta, Expression left, Expression right) {
        return new And(meta, left, right);
    }

    public static And eAnd(Expression left, Expression right) {
        return new And(null, left, right);
    }

    public static Not eNand(Expression left, Expression right) throws InvalidIRException {
        return eNot(eAnd(left, right));
    }

    public static Or eOr(SourceWithMetadata meta, Expression left, Expression right) {
        return new Or(meta, left, right);
    }

    public static Or eOr(Expression left, Expression right) {
        return new Or(null, left, right);
    }

    public static Or eXor(Expression left, Expression right) throws InvalidIRException {
        return eOr(eAnd(eNot(left), right), eAnd(left, eNot(right)));
    }

    public static RegexEq eRegexEq(SourceWithMetadata meta, Expression left, ValueExpression right) throws InvalidIRException {
        return new RegexEq(meta, left, right);
    }

    public static RegexEq eRegexEq(Expression left, ValueExpression right) throws InvalidIRException {
        return new RegexEq(null, left, right);
    }

    public static Expression eRegexNeq(SourceWithMetadata meta, Expression left, ValueExpression right) throws InvalidIRException {
        return eNot(eRegexEq(meta, left, right));
    }

    public static Expression eRegexNeq(Expression left, ValueExpression right) throws InvalidIRException {
        return eNot(eRegexEq(left, right));
    }

    public static Neq eNeq(SourceWithMetadata meta, Expression left, Expression right) {
        return new Neq(meta, left, right);
    }
    public static Neq eNeq(Expression left, Expression right) {
        return new Neq(null, left, right);
    }

    public static In eIn(SourceWithMetadata meta, Expression left, Expression right) {
        return new In(meta, left, right);
    }

    public static In eIn(Expression left, Expression right) {
        return new In(null, left, right);
    }

    public static Not eNot(SourceWithMetadata meta, Expression expr) throws InvalidIRException {
        return new Not(meta, expr);
    }

    public static Not eNot(Expression expr) throws InvalidIRException {
        return new Not(null, expr);
    }

    public static BooleanExpression eTruthy(SourceWithMetadata meta, Expression expr) throws InvalidIRException {
        if (expr instanceof BooleanExpression) {
            return (BooleanExpression) expr;
        }
        return new Truthy(meta, expr);
    }
    public static BooleanExpression eTruthy(Expression expr) throws InvalidIRException {
        return eTruthy(null, expr);
    }

    public static Statement iCompose(ComposedStatement.IFactory factory, SourceWithMetadata meta, Statement... statements) throws InvalidIRException {
        if (statements.length == 0 ) {
            return new NoopStatement(meta);
        } else if (statements.length == 1 ) {
            return statements[0];
        } else {
            return factory.make(meta, Arrays.asList(statements));
        }
    }

    public static Statement iComposeSequence(SourceWithMetadata meta, Statement... statements) throws InvalidIRException {
        return iCompose(ComposedSequenceStatement::new, meta, statements);
    }

    public static Statement iComposeSequence(Statement... statements) throws InvalidIRException {
        return iComposeSequence(null, statements);
    }

    public static Statement iComposeParallel(SourceWithMetadata meta, Statement... statements) throws InvalidIRException {
        return iCompose(ComposedParallelStatement::new, meta, statements);
    }

    public static Statement iComposeParallel(Statement... statements) throws InvalidIRException {
        return iComposeParallel(null, statements);
    }

    public static NoopStatement noop(SourceWithMetadata meta) {
        return new NoopStatement(meta);
    }

    public static NoopStatement noop() {
        return new NoopStatement(null);
    }

    public static PluginStatement iPlugin(SourceWithMetadata meta, PluginDefinition.Type pluginType, String pluginName, Map<String, Object> pluginArguments) {
        return new PluginStatement(meta, new PluginDefinition(pluginType, pluginName, pluginArguments));
    }

    public static PluginStatement iPlugin(PluginDefinition.Type type, String pluginName, Map<String, Object> pluginArguments) {
        return iPlugin(null, type, pluginName, pluginArguments);
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

    public static IfStatement iIf(SourceWithMetadata meta,
                                  Expression condition,
                                  Statement ifTrue,
                                  Statement ifFalse) throws InvalidIRException {
        BooleanExpression booleanExpression = eTruthy(meta, condition);
        return new IfStatement(meta, booleanExpression, ifTrue, ifFalse);
    }

    public static IfStatement iIf(Expression condition,
                                  Statement ifTrue,
                                  Statement ifFalse) throws InvalidIRException {
        return iIf(null, condition, ifTrue, ifFalse);
    }

    public static IfStatement iIf(Expression condition,
                                  Statement ifTrue) throws InvalidIRException {
        return iIf(null, condition, ifTrue, noop());
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

    public static PluginVertex gPlugin(SourceWithMetadata sourceWithMetadata, PluginDefinition.Type pluginType, String pluginName, Map<String, Object> pluginArgs) {
       return new PluginVertex(sourceWithMetadata, new PluginDefinition(pluginType, pluginName, pluginArgs));
    }

    public static PluginVertex gPlugin(PluginDefinition.Type type, String pluginName, Map<String, Object> pluginArgs) {
        return gPlugin(null, type, pluginName, pluginArgs);
    }

    public static PluginVertex gPlugin(PluginDefinition.Type type, String pluginName, String id) {
        return gPlugin(type, pluginName, argumentBuilder().put("id", id).build());
    }

    public static PluginVertex gPlugin(PluginDefinition.Type type, String pluginName) {
        return gPlugin(null, type, pluginName, new HashMap<>());
    }


    public static IfVertex gIf(SourceWithMetadata meta, BooleanExpression expression) {
       return new IfVertex(expression);
    }

    public static IfVertex gIf(BooleanExpression expression) {
       return new IfVertex(expression);
    }
}

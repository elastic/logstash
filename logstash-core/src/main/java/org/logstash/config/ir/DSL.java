/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


package org.logstash.config.ir;

import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

import org.logstash.common.IncompleteSourceWithMetadataException;
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

    public static Not eNand(SourceWithMetadata meta, Expression left, Expression right) throws InvalidIRException {
        return eNot(meta, eAnd(left, right));
    }

    public static Or eOr(SourceWithMetadata meta, Expression left, Expression right) {
        return new Or(meta, left, right);
    }

    public static Or eOr(Expression left, Expression right) {
        return new Or(null, left, right);
    }

    public static Or eXor(SourceWithMetadata meta, Expression left, Expression right) throws InvalidIRException {
        return eOr(meta, eAnd(eNot(left), right), eAnd(left, eNot(right)));
    }

    public static RegexEq eRegexEq(SourceWithMetadata meta, Expression left, ValueExpression right) throws InvalidIRException {
        return new RegexEq(meta, left, right);
    }

    public static RegexEq eRegexEq(Expression left, ValueExpression right) throws InvalidIRException {
        return new RegexEq(null, left, right);
    }

    public static Expression eRegexNeq(SourceWithMetadata meta, Expression left, ValueExpression right) throws InvalidIRException {
        return new Not(meta, eRegexEq(meta, left, right));
    }

    public static Expression eRegexNeq(Expression left, ValueExpression right) throws InvalidIRException {
        return new Not(null, eRegexEq(null, left, right));
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
        try {
            SourceWithMetadata meta = new SourceWithMetadata("internal", "noop", 0, 0, UUID.randomUUID().toString());
        } catch (IncompleteSourceWithMetadataException e) {
            // Should never happen
            throw new RuntimeException("Noop could not instantiate metadata, this should never happen");
        }
        return new NoopStatement(null);
    }

    public static PluginStatement iPlugin(SourceWithMetadata meta, PluginDefinition.Type pluginType, String pluginName, Map<String, Object> pluginArguments) {
        return new PluginStatement(meta, new PluginDefinition(pluginType, pluginName, pluginArguments));
    }

    public static PluginStatement iPlugin(SourceWithMetadata meta, PluginDefinition.Type pluginType, String pluginName, String pluginId) {
        return iPlugin(meta, pluginType, pluginName, pargs().put("id", pluginId).build());
    }

    public static PluginStatement iPlugin(SourceWithMetadata meta, PluginDefinition.Type pluginType, String pluginName) {
        return iPlugin(meta, pluginType, pluginName, pargs().build());
    }

    public static IfStatement iIf(SourceWithMetadata meta,
                                  Expression condition,
                                  Statement ifTrue,
                                  Statement ifFalse) throws InvalidIRException {
        BooleanExpression booleanExpression = eTruthy(meta, condition);
        return new IfStatement(meta, booleanExpression, ifTrue, ifFalse);
    }

    public static IfStatement iIf(SourceWithMetadata meta, Expression condition,
                                  Statement ifTrue) throws InvalidIRException {
        return iIf(meta, condition, ifTrue, noop());
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

    public static PluginVertex gPlugin(SourceWithMetadata meta, PluginDefinition.Type type, String pluginName, String id) {
        return gPlugin(meta, type, pluginName, argumentBuilder().put("id", id).build());
    }

    public static PluginVertex gPlugin(SourceWithMetadata meta, PluginDefinition.Type type, String pluginName) {
        return gPlugin(meta, type, pluginName, new HashMap<>());
    }

    public static PluginVertex gPlugin(SourceWithMetadata meta, PluginDefinition pluginDefinition) {
        return gPlugin(meta, pluginDefinition.getType(), pluginDefinition.getName(), pluginDefinition.getArguments());
    }

    public static IfVertex gIf(SourceWithMetadata meta, BooleanExpression expression) {
       return new IfVertex(meta, expression);
    }
}

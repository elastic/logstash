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

import org.jruby.RubyHash;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.common.SourceWithMetadata;
import org.logstash.config.ir.graph.Graph;
import org.logstash.config.ir.imperative.Statement;
import org.logstash.plugins.ConfigVariableExpander;

import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.stream.Collectors;

import static java.util.stream.Collectors.*;

/**
 * Java Implementation of the config compiler that is implemented by wrapping the Ruby
 * {@code LogStash::Compiler}.
 */
public final class ConfigCompiler {

    private ConfigCompiler() {
        // Utility Class
    }

    /**
     * @param sourcesWithMetadata Logstash Config partitioned
     * @param supportEscapes The value of the setting {@code config.support_escapes}
     * @param cve Config variable expander. Substitute variable with value in secret store, env, default config value
     * @return Compiled {@link PipelineIR}
     * @throws InvalidIRException if the the configuration contains errors
     */
    @SuppressWarnings("unchecked")
    public static PipelineIR configToPipelineIR(final List<SourceWithMetadata> sourcesWithMetadata,
                                                final boolean supportEscapes, ConfigVariableExpander cve) throws InvalidIRException {
        return compileSources(sourcesWithMetadata, supportEscapes, cve);
    }

    public static PipelineIR compileSources(List<SourceWithMetadata> sourcesWithMetadata, boolean supportEscapes, ConfigVariableExpander cve) throws InvalidIRException {
        Map<PluginDefinition.Type, List<Graph>> groupedPipelineSections = sourcesWithMetadata.stream()
                .map(swm -> compileGraph(swm, supportEscapes, cve))
                .flatMap(m -> m.entrySet().stream())
                .filter(e -> e.getValue() != null)
                .collect(groupingBy(Map.Entry::getKey,
                            mapping(Map.Entry::getValue, toList())));

        Graph inputGraph = Graph.combine(groupedPipelineSections.get(PluginDefinition.Type.INPUT).toArray(new Graph[0])).graph;
        Graph outputGraph = Graph.combine(groupedPipelineSections.get(PluginDefinition.Type.OUTPUT).toArray(new Graph[0])).graph;
        Graph filterGraph = groupedPipelineSections.get(PluginDefinition.Type.FILTER).stream()
                .reduce(ConfigCompiler::chainWithUntypedException).orElse(null);

        String originalSource = sourcesWithMetadata.stream().map(SourceWithMetadata::getText).collect(Collectors.joining("\n"));
        return new PipelineIR(inputGraph, filterGraph, outputGraph, originalSource);
    }

    private static Graph chainWithUntypedException(Graph g1, Graph g2) {
        try {
            return g1.chain(g2);
        } catch (InvalidIRException iirex) {
            throw new IllegalArgumentException(iirex);
        }
    }

    private static Map<PluginDefinition.Type, Statement> compileImperative(SourceWithMetadata sourceWithMetadata,
                                                                           boolean supportEscapes) {
        final IRubyObject compiler = RubyUtil.RUBY.executeScript(
                "require 'logstash/compiler'\nLogStash::Compiler",
                ""
        );
        // invoke Ruby interpreter to execute LSCL treetop
        final IRubyObject code = compiler.callMethod(RubyUtil.RUBY.getCurrentContext(), "compile_imperative",
                new IRubyObject[]{
                        JavaUtil.convertJavaToRuby(RubyUtil.RUBY, sourceWithMetadata),
                        RubyUtil.RUBY.newBoolean(supportEscapes)
                });
        RubyHash hash = (RubyHash) code;
        Map<PluginDefinition.Type, Statement> result = new HashMap<>();
        result.put(PluginDefinition.Type.INPUT, readStatementFromRubyHash(hash, "input"));
        result.put(PluginDefinition.Type.FILTER, readStatementFromRubyHash(hash, "filter"));
        result.put(PluginDefinition.Type.OUTPUT, readStatementFromRubyHash(hash, "output"));
        return result;
    }

    private static Statement readStatementFromRubyHash(RubyHash hash, String key) {
        IRubyObject inputValue = hash.fastARef(RubyUtil.RUBY.newSymbol(key));
        return inputValue.toJava(Statement.class);
    }

    private static Map<PluginDefinition.Type, Graph> compileGraph(SourceWithMetadata swm, boolean supportEscapes, ConfigVariableExpander cve) {
        Map<PluginDefinition.Type, Statement> pluginStatements = compileImperative(swm, supportEscapes);
        return pluginStatements.entrySet().stream()
                .collect(Collectors.toMap(Map.Entry::getKey, e -> toGraphWithUntypedException(e.getValue(), cve)));
    }

    private static Graph toGraphWithUntypedException(Statement s, ConfigVariableExpander cve) {
        try {
            return s.toGraph(cve);
        } catch (InvalidIRException iirex) {
            throw new IllegalArgumentException(iirex);
        }
    }
}

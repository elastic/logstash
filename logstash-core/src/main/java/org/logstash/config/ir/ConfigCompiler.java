package org.logstash.config.ir;

import org.jruby.RubyHash;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.common.IncompleteSourceWithMetadataException;
import org.logstash.common.SourceWithMetadata;
import org.logstash.config.ir.graph.Graph;
import org.logstash.config.ir.imperative.Statement;

import java.util.*;
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
     * @param config Logstash Config String
     * @param supportEscapes The value of the setting {@code config.support_escapes}
     * @return Compiled {@link PipelineIR}
     * @throws IncompleteSourceWithMetadataException On Broken Configuration
     */
    public static PipelineIR configToPipelineIR(final String config, final boolean supportEscapes)
        throws IncompleteSourceWithMetadataException {
        SourceWithMetadata sourceWithMetadata = new SourceWithMetadata("str", "pipeline", 0, 0, config);
        try {
            return compileSources(Arrays.asList(sourceWithMetadata), supportEscapes);
        } catch (InvalidIRException iirex) {
            throw new IllegalArgumentException(iirex);
        }
    }

    public static PipelineIR compileSources(List<SourceWithMetadata> sourcesWithMetadata, boolean supportEscapes) throws InvalidIRException {
        Map<PluginDefinition.Type, List<Graph>> groupedPipelineSections = sourcesWithMetadata.stream()
                .map(swm -> compileGraph(swm, supportEscapes))
                .flatMap(m -> m.entrySet().stream())
                .filter(e -> e.getValue() != null)
                .collect(groupingBy(Map.Entry::getKey,
                                mapping(Map.Entry::getValue, toList())));

        Graph inputGraph = Graph.combine(groupedPipelineSections.get(PluginDefinition.Type.INPUT).toArray(new Graph[0])).graph;
        Graph outputGraph = Graph.combine(groupedPipelineSections.get(PluginDefinition.Type.OUTPUT).toArray(new Graph[0])).graph;
        Graph filterGraph = groupedPipelineSections.get(PluginDefinition.Type.FILTER).stream()
                .reduce(ConfigCompiler::chainWithUntypedException).orElse(null);

        String originalSource = sourcesWithMetadata.stream().map(SourceWithMetadata::getText).collect(joining("\n"));
        return new PipelineIR(inputGraph, filterGraph, outputGraph, originalSource);
    }

    private static Graph chainWithUntypedException(Graph g1, Graph g2) {
        try {
            return g1.chain(g2);
        } catch (InvalidIRException iirex) {
            throw new IllegalArgumentException(iirex);
        }
    }

    private static Map<PluginDefinition.Type, Graph> compileGraph(SourceWithMetadata swm, boolean supportEscapes) {
        Map<PluginDefinition.Type, Statement> pluginStatements = compileImperative(swm, supportEscapes);
        return pluginStatements.entrySet().stream()
                .collect(Collectors.toMap(Map.Entry::getKey, e -> toGraphWithUntypedException(e.getValue())));
    }

    private static Graph toGraphWithUntypedException(Statement s) {
        try {
            return s.toGraph();
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
        final IRubyObject code =
            compiler.callMethod(RubyUtil.RUBY.getCurrentContext(), "compile_imperative",
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
        IRubyObject inputValue = hash.op_aref(RubyUtil.RUBY.getCurrentContext(), RubyUtil.RUBY.newSymbol(key));
        return inputValue.toJava(Statement.class);
    }
}

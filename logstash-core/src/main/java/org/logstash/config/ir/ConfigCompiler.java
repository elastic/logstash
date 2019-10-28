package org.logstash.config.ir;

import org.jruby.RubyHash;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.common.IncompleteSourceWithMetadataException;
import org.logstash.common.SourceWithMetadata;
import org.logstash.config.ir.graph.Graph;
import org.logstash.config.ir.imperative.PluginStatement;
import org.logstash.config.ir.imperative.Statement;

import java.util.*;

import static java.util.stream.Collectors.joining;
import static java.util.stream.Collectors.toList;

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
        final IRubyObject compiler = RubyUtil.RUBY.executeScript(
            "require 'logstash/compiler'\nLogStash::Compiler",
            ""
        );

        SourceWithMetadata sourceWithMetadata = new SourceWithMetadata("str", "pipeline", 0, 0, config);
        try {
            return compileSources(Arrays.asList(sourceWithMetadata), supportEscapes);
        } catch (InvalidIRException iirex) {
            throw new IllegalArgumentException(iirex);
        }
    }

    public static PipelineIR compileSources(List<SourceWithMetadata> sourcesWithMetadata, boolean supportEscapes) throws InvalidIRException {
        List<Map<PluginDefinition.Type, Graph>> graphSections = new ArrayList<>();
        for (SourceWithMetadata swm : sourcesWithMetadata) {
            Map<PluginDefinition.Type, Graph> stringGraphMap = compileGraph(swm, supportEscapes);
            graphSections.add(stringGraphMap);
        }

        List<Graph> inputGraphs = graphSections.stream()
                .map(map -> map.get(PluginDefinition.Type.INPUT))
                .filter(Objects::nonNull)
                .collect(toList());
        Graph inputGraph = Graph.combine(inputGraphs.toArray(new Graph[0])).graph;

        List<Graph> outputGraphs = graphSections.stream()
                .map(map -> map.get(PluginDefinition.Type.OUTPUT))
                .filter(Objects::nonNull)
                .collect(toList());
        Graph outputGraph = Graph.combine(outputGraphs.toArray(new Graph[0])).graph;

        Graph filterGraph = null;
        for (Map<PluginDefinition.Type, Graph> graphSection : graphSections) {
            if (graphSection.containsKey(PluginDefinition.Type.FILTER)) {
                Graph filter = graphSection.get(PluginDefinition.Type.FILTER);
                if (filterGraph == null) {
                    filterGraph = filter;
                } else {
                    filterGraph.chain(filter);
                }
            }
        }

        String originalSource = sourcesWithMetadata.stream().map(SourceWithMetadata::getText).collect(joining("\n"));
        return new PipelineIR(inputGraph, filterGraph, outputGraph, originalSource);
    }

    private static Map<PluginDefinition.Type, Graph> compileGraph(SourceWithMetadata swm, boolean supportEscapes) throws InvalidIRException {
        Map<PluginDefinition.Type, Graph> graphMap = new HashMap<>();
        Map<PluginDefinition.Type, Statement> map = compileImperative(swm, supportEscapes);
        for (Map.Entry<PluginDefinition.Type, Statement> entry : map.entrySet()) {
            final PluginDefinition.Type section = entry.getKey();
            final Statement compiled = entry.getValue();
            graphMap.put(section, compiled.toGraph());
        }
        return graphMap;
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
        result.put(PluginDefinition.Type.INPUT, readRubyHashValue(hash, "input", Statement.class));
        result.put(PluginDefinition.Type.FILTER, readRubyHashValue(hash, "filter", Statement.class));
        result.put(PluginDefinition.Type.OUTPUT, readRubyHashValue(hash, "output", Statement.class));
        return result;
    }

    private static <T> T readRubyHashValue(RubyHash hash, String key, Class<T> valueType) {
        IRubyObject inputValue = hash.op_aref(RubyUtil.RUBY.getCurrentContext(), RubyUtil.RUBY.newSymbol(key));
        return inputValue.toJava(valueType);
    }
}

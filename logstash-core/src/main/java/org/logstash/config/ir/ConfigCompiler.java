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

        Graph inputGraph = combineGraphSectionsOf(graphSections, PluginDefinition.Type.INPUT);
        Graph outputGraph = combineGraphSectionsOf(graphSections, PluginDefinition.Type.OUTPUT);

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

    private static Graph combineGraphSectionsOf(List<Map<PluginDefinition.Type, Graph>> graphSections,
                                                PluginDefinition.Type input) throws InvalidIRException {
        List<Graph> inputGraphs = graphSections.stream()
                .map(map -> map.get(input))
                .filter(Objects::nonNull)
                .collect(toList());
        return Graph.combine(inputGraphs.toArray(new Graph[0])).graph;
    }

    private static Map<PluginDefinition.Type, Graph> compileGraph(SourceWithMetadata swm, boolean supportEscapes) {
        Map<PluginDefinition.Type, Statement> pluginStatements = compileImperative(swm, supportEscapes);
        return pluginStatements.entrySet().stream()
                .collect(Collectors.toMap(Map.Entry::getKey, e -> compileStatementToGraph(e.getValue())));
    }

    private static Graph compileStatementToGraph(Statement s) {
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

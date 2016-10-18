package org.logstash.config.compiler;

import org.logstash.Event;
import org.logstash.config.compiler.compiled.ICompiledExpression;
import org.logstash.config.compiler.compiled.ICompiledProcessor;
import org.logstash.config.ir.graph.BooleanEdge;
import org.logstash.config.ir.graph.Edge;
import org.logstash.config.ir.graph.IfVertex;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Created by andrewvc on 10/13/16.
 */
public class IfCompiler {
    public class CompiledIf implements ICompiledProcessor {
        private final ICompiledExpression compiledExpression;
        private final List<BooleanEdge> trueEdges;
        private final List<BooleanEdge> falseEdges;

        public CompiledIf(ICompiledExpression compiledExpression, List<BooleanEdge> trueEdges, List<BooleanEdge> falseEdges) {
            this.compiledExpression = compiledExpression;
            this.trueEdges = trueEdges;
            this.falseEdges = falseEdges;
        }

        @Override
        public Map<Edge, List<Event>> process(List<Event> events) {
            List<Boolean> booleans = compiledExpression.execute(events);

            ArrayList<Event> trueEvents = new ArrayList<>(events.size());
            ArrayList<Event> falseEvents = new ArrayList<>(events.size());
            for (int i = 0; i < events.size(); i++) {
                if (booleans.get(i)) {
                    trueEvents.add(events.get(i));
                } else {
                    falseEvents.add(events.get(i));
                }
            }

            Map<Edge, List<Event>> out = new HashMap<>();
            trueEdges.stream().forEach(e -> out.put(e, trueEvents));
            falseEdges.stream().forEach(e -> out.put(e, falseEvents));
            return out;
        }

        @Override
        public void register() {
            // Nothing to do!
        }

        @Override
        public void stop() {
            // Nothing to do!
        }
    }

    private final IExpressionCompiler expressionCompiler;

    public IfCompiler(IExpressionCompiler expressionCompiler) {
        this.expressionCompiler = expressionCompiler;
    }

    public ICompiledProcessor compile(IfVertex vertex) throws CompilationError {
        ICompiledExpression compiledExpression = expressionCompiler.compile(vertex.getBooleanExpression());
        return new CompiledIf(compiledExpression, vertex.getOutgoingBooleanEdgesByType(true), vertex.getOutgoingBooleanEdgesByType(false));
    }
}

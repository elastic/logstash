package org.logstash.config.ir;

import org.junit.Test;
import org.logstash.Event;
import org.logstash.config.pipeline.PassthroughProcessor;
import org.logstash.config.pipeline.Pipeline;
import org.logstash.config.pipeline.PipelineRunner;
import org.logstash.config.compiler.*;
import org.logstash.config.compiler.compiled.ICompiledInputPlugin;
import org.logstash.config.compiler.compiled.ICompiledProcessor;
import org.logstash.config.pipeline.pipette.*;
import org.logstash.config.ir.graph.Graph;
import org.logstash.config.ir.graph.PluginVertex;

import java.util.Collections;
import java.util.List;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.SynchronousQueue;
import java.util.concurrent.ThreadLocalRandom;
import java.util.stream.Collectors;

import static org.logstash.config.ir.DSL.*;
import static org.logstash.config.ir.PluginDefinition.Type.*;

/**
 * Created by andrewvc on 10/11/16.
 */
public class PipelineRunnerTest {
    @Test
    public void testPipelineRunner() throws InvalidIRException, CompilationError, PipetteExecutionException, InterruptedException {
        Graph inputSection = iComposeParallel(iPlugin(INPUT, "generator"), iPlugin(INPUT, "stdin")).toGraph();
        Graph filterSection = iIf(eEq(eEventValue("[foo]"), eEventValue("[bar]")),
                iPlugin(FILTER, "grok"),
                iPlugin(FILTER, "kv")).toGraph();
        Graph outputSection = iIf(eGt(eEventValue("[baz]"), eValue(1000)),
                iComposeParallel(
                        iPlugin(OUTPUT, "s3"),
                        iPlugin(OUTPUT, "elasticsearch")),
                iPlugin(OUTPUT, "stdout")).toGraph();

        Pipeline pipeline = new Pipeline(inputSection, filterSection, outputSection);

        BlockingQueue<List<Event>> queue = new SynchronousQueue<>();

        IExpressionCompiler expressionCompiler = new RubyExpressionCompiler();
        IPluginCompiler pluginCompiler = new IPluginCompiler() {
            @Override
            public ICompiledInputPlugin compileInput(PluginVertex vertex) throws CompilationError {
                return new ICompiledInputPlugin() {
                    public PipetteSourceEmitter onWriteWriter;

                    @Override
                    public void register() {

                    }

                    public Event generateEvent() {
                        Event e = new Event();
                        int seed = ThreadLocalRandom.current().nextInt(1,100);
                        e.setField("[foo]", (seed % 2 == 0 ? "String1" : "String2"));
                        e.setField("[bar]", (seed % 2 == 0 ? "String1" : "String2"));
                        e.setField("[baz]", (seed % 2 == 0 ? 500 : 5000));

                        List<Event> events = Collections.singletonList(e);

                        return e;
                    }

                    public List<Event> generateEvents() {
                        return Collections.nCopies(2, ThreadLocalRandom.current().nextInt(5,10)).
                                stream().
                                map(i -> generateEvent()).
                                collect(Collectors.toList());
                    }

                    @Override
                    public void start() throws PipetteExecutionException {
                        for (int i = 0; i < 10; i++) {
                            onWriteWriter.emit(generateEvents());
                        }
                    }

                    @Override
                    public void stop() {

                    }

                    @Override
                    public void onEvents(PipetteSourceEmitter sourceWriter) {
                        this.onWriteWriter = sourceWriter;
                    }
                };
            }

            @Override
            public ICompiledProcessor compileFilter(PluginVertex vertex) throws CompilationError {
                return new PassthroughProcessor(vertex);
            }

            @Override
            public ICompiledProcessor compileOutput(PluginVertex vertex) throws CompilationError {
                return new PassthroughProcessor(vertex);
            }
        };

        IPipetteConsumerFactory queueWriterFactory = () -> new IPipetteConsumer() {
            @Override
            public void process(List<Event> events) throws PipetteExecutionException {
                try {
                    System.out.println("WRITEQ");
                    queue.put(events);
                } catch (InterruptedException e) {
                    throw new PipetteExecutionException(e.getMessage(), e);
                }
            }

            @Override
            public void stop() throws PipetteExecutionException {

            }
        };

        IPipetteProducerFactory queueReaderFactory = new IPipetteProducerFactory() {
            @Override
            public IPipetteProducer make() {
                return new IPipetteProducer() {
                    public PipetteSourceEmitter sourceEmitter;

                    @Override
                    public void start() throws PipetteExecutionException {
                        while (true) {
                            try {
                                List<Event> events = queue.take();
                                System.out.println("READQ" + events);
                                sourceEmitter.emit(events);
                            } catch (InterruptedException e) {
                                throw new PipetteExecutionException(e.getMessage(), e);
                            }
                        }
                    }

                    @Override
                    public void stop() {
                    }

                    @Override
                    public void onEvents(PipetteSourceEmitter sourceEmitter) {
                        this.sourceEmitter = sourceEmitter;
                    }
                };
            }
        };

        //PipelineRunner runner = new PipelineRunner(pipeline, queueWriterFactory, queueReaderFactory, expressionCompiler, pluginCompiler, null);
        //runner.start(1);
        //runner.join();
    }
}

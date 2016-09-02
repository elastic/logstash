package org.logstash.config.pipeline;

import org.logstash.Event;
import org.logstash.config.compiler.*;
import org.logstash.config.compiler.compiled.ICompiledInputPlugin;
import org.logstash.config.compiler.compiled.ICompiledProcessor;
import org.logstash.config.pipeline.pipette.*;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.Pipeline;
import org.logstash.config.ir.PluginDefinition;
import org.logstash.config.ir.graph.IfVertex;
import org.logstash.config.ir.graph.PluginVertex;
import org.logstash.config.ir.graph.SpecialVertex;
import org.logstash.config.ir.graph.Vertex;

import java.util.*;
import java.util.concurrent.BlockingQueue;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Created by andrewvc on 9/22/16.
 */
public class PipelineRunner {
    private final Pipeline pipeline;
    private final IPluginCompiler pluginCompiler;
    private final IExpressionCompiler expressionCompiler;
    private final HashMap<PluginVertex, ICompiledInputPlugin> inputVerticesToCompiled;
    private final Collection<Pipette> inputPipettes;
    private final HashMap<Pipette, Thread> pipettesThreads;
    private final Map<Vertex, ICompiledProcessor> processorVerticesToCompiled;
    private final List<Vertex> orderedPostQueue;
    private final Collection<Pipette> processorPipettes;
    private final BlockingQueue<List<Event>> queue;
    private final QueueReadSource queueReadSource;
    private final QueueWriteProcessor queueWriteProcessor;
    private final IfCompiler ifCompiler;
    private final PipelineRunnerObserver observer;

    public PipelineRunner(Pipeline pipeline, BlockingQueue<List<Event>> queue, IExpressionCompiler expressionCompiler, IPluginCompiler pluginCompiler, PipelineRunnerObserver observer) throws CompilationError, InvalidIRException {
        this.pipeline = pipeline;
        this.expressionCompiler = expressionCompiler;
        this.observer = observer != null ? observer : new PipelineRunnerObserver();
        this.ifCompiler = new IfCompiler(expressionCompiler);
        this.pluginCompiler = pluginCompiler;
        this.pipettesThreads = new HashMap<Pipette, Thread>();
        this.queue = queue;
        this.queueWriteProcessor = new QueueWriteProcessor(queue);
        this.queueReadSource = new QueueReadSource(queue);

        // Handle stuff before the queue, e.g. inputs
        this.inputVerticesToCompiled = compileInputs();
        this.inputPipettes = new ArrayList<>();

        // Handle stuff after the queue, e.g. processors
        this.orderedPostQueue = pipeline.getPostQueue();
        this.processorVerticesToCompiled = this.compileProcessors();
        this.processorPipettes = new ArrayList<>();
        this.observer.initialize(this);
    }

    public void start(int workers) throws PipetteExecutionException, CompilationError {
        observer.beforeStart(this);
        startInputs();
        startProcessors(workers);
        observer.afterStart(this);
    }

    public void join() throws InterruptedException, PipetteExecutionException {
        // Join on input threads
        for (Map.Entry<Pipette,Thread> entry : pipettesThreads(inputPipettes).entrySet()) {
            entry.getValue().join();
            System.out.println("Input thread finished: " + entry.getKey());
        }

        while (queue.peek() != null) {
            System.out.println("Waiting for queue to shutdown");
        }

        // Join on processors / close them out
        for (Map.Entry<Pipette,Thread> entry : pipettesThreads(processorPipettes).entrySet()) {
            Pipette pipette = entry.getKey();
            Thread thread = entry.getValue();

            pipette.stop();
            thread.join();

            System.out.println("Processor thread finished: " + pipette);
        }

    }

    public Map<Pipette,Thread> pipettesThreads(Collection<Pipette> pipettes) {
        return pipettes.stream().collect(Collectors.toMap(Function.identity(), pipettesThreads::get));
    }

    public void stop(int workers) throws PipetteExecutionException {
        observer.beforeStop(this);
        stopInputs();
        observer.inputsStopped(this);
        stopProcessors();
        observer.afterStop(this);
    }

    private Pipette createProcessorPipette(String name) {
        OrderedVertexPipetteProcessor processor = new OrderedVertexPipetteProcessor(this.orderedPostQueue, this.processorVerticesToCompiled, pipeline.getQueue(), observer);
        return new Pipette(name, queueReadSource, processor);
    }

    private Map<Vertex, ICompiledProcessor> compileProcessors() throws CompilationError {
        Map<Vertex, ICompiledProcessor> vertexToCompiled = new HashMap<>(orderedPostQueue.size());

        for (Vertex v : orderedPostQueue) {
            if (v instanceof PluginVertex) {
                PluginDefinition pluginDefinition = ((PluginVertex) v).getPluginDefinition();

                ICompiledProcessor compiled;
                switch (pluginDefinition.getType()) {
                    case FILTER:
                        compiled = pluginCompiler.compileFilter((PluginVertex) v);
                        break;
                    case OUTPUT:
                        compiled = pluginCompiler.compileOutput((PluginVertex) v);
                        break;
                    default:
                        throw new CompilationError("Invariant violated! only filter / output plugins expected in filter/output stage");
                }

                if (compiled == null) {
                    throw new CompilationError("Compilation of vertex returned null! Vertex:" + v);
                }

                compiled.register();
                vertexToCompiled.put(v, compiled);
            } else if (v instanceof SpecialVertex) {
                vertexToCompiled.put(v, new PassthroughProcessor((SpecialVertex) v));
            } else if (v instanceof IfVertex) {
                vertexToCompiled.put(v, ifCompiler.compile((IfVertex) v));
            } else {
                throw new CompilationError("Invariant violated!, only plugin / special vertices were expected! Got: " + v);
            }
        }

        return vertexToCompiled;
    }

    private HashMap<PluginVertex, ICompiledInputPlugin> compileInputs() throws CompilationError {
        HashMap<PluginVertex, ICompiledInputPlugin> compiled = new HashMap<>();
        for (PluginVertex pv : pipeline.getInputPluginVertices()) {
            ICompiledInputPlugin c = pluginCompiler.compileInput(pv);
            c.register();
            compiled.put(pv, c);
        }
        return compiled;
    }

    private Collection<Pipette> createInputPipettes(Queue<List<Event>> queue) throws CompilationError {
        List<Pipette> inputPipettes = new ArrayList<>(this.inputVerticesToCompiled.size());
        for (Map.Entry<PluginVertex, ICompiledInputPlugin> entry : this.inputVerticesToCompiled.entrySet()) {
            String name = "Input[" + entry.getKey().getId() + "]";
            Pipette inputPipette = new Pipette(name, entry.getValue(), queueWriteProcessor, observer);
            inputPipettes.add(inputPipette);
        }
        return inputPipettes;
    }

    public void startInputs() throws PipetteExecutionException, CompilationError {
        observer.beforeInputsStart(this);
        stopInputs();
        this.inputPipettes.clear();
        Collection<Pipette> newPipettes = createInputPipettes(this.queue);
        this.inputPipettes.addAll(newPipettes);
        startPipettes(inputPipettes);
        observer.afterInputsStart(this);
    }

    public void stopInputs() throws PipetteExecutionException {
        stopPipettes(this.inputPipettes);
    }

    public void startProcessors(int workers) throws PipetteExecutionException {
        observer.beforeProcessorsStart(this);
        stopProcessors();
        this.processorPipettes.clear();

        for (int i = 0; i < workers; i++) {
            String name = "> PostQueue Processor[" + i + "]";
            this.processorPipettes.add(createProcessorPipette(name));
        }

        startPipettes(this.processorPipettes);
        observer.afterProcessorsStart(this);
    }

    private void stopProcessors() throws PipetteExecutionException {
        stopPipettes(this.processorPipettes);
    }

    private void stopPipettes(Collection<Pipette> pipettes) throws PipetteExecutionException {
        for (Pipette pipette : pipettes) {
            stopPipette(pipette);
        }
    }

    private void startPipettes(Collection<Pipette> pipettes) {
        for (Pipette pipette : pipettes) {
            startPipette(pipette);
        }
    }

    private Thread startPipette(Pipette pipette) {
        Thread thread = new Thread(() -> {
            try {
                pipette.start();
            } catch (PipetteExecutionException e) {
                //TODO: We need some failure handling here
                e.printStackTrace();
            }
        });
        thread.start();

        this.pipettesThreads.put(pipette, thread);

        return thread;
    }

    private void stopPipette(Pipette pipette) throws PipetteExecutionException {
        pipette.stop();
        Thread thread = pipettesThreads.get(pipette);
        if (thread.isAlive()) {
            throw new PipetteExecutionException(
                    "Pipette stop succeeded, but its thread is still alive! " +
                            "Pipette: "  + pipette + " Thread " + thread
            );
        }
        pipettesThreads.remove(pipette);
    }
}

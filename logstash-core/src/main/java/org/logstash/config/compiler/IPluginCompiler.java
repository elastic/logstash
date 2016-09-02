package org.logstash.config.compiler;

import org.logstash.config.compiler.compiled.ICompiledInputPlugin;
import org.logstash.config.compiler.compiled.ICompiledProcessor;
import org.logstash.config.ir.graph.PluginVertex;

/**
 * Created by andrewvc on 9/22/16.
 */
public interface IPluginCompiler {
   ICompiledInputPlugin compileInput(PluginVertex vertex) throws CompilationError;
   ICompiledProcessor compileFilter(PluginVertex vertex) throws CompilationError;
   ICompiledProcessor compileOutput(PluginVertex vertex) throws CompilationError;
}

package org.logstash.gradle

import org.jruby.Ruby
import org.jruby.embed.PathType
import org.jruby.embed.ScriptingContainer

final class RubyGradleUtils {

  private final File buildDir

  private final File projectDir

  RubyGradleUtils(File buildDir, File projectDir) {
    this.buildDir = buildDir
    this.projectDir = projectDir
  }

  /**
   * Executes a bundler bin script with given parameters.
   * @param pwd Current worker directory to execute in
   * @param bundleBin Bundler Bin Script
   * @param args CLI Args to Use with Bundler
   */
  void bundle(String pwd, String bundleBin, Iterable<String> args) {
    bundle(pwd, bundleBin, args, Collections.emptyMap())
  }

  /**
   * Executes a bundler bin script with given parameters.
   * @param pwd Current worker directory to execute in
   * @param bundleBin Bundler Bin Script
   * @param args CLI Args to Use with Bundler
   * @param env Environment Variables to Set
   */
  void bundle(String pwd, String bundleBin, Iterable<String> args, Map<String, String> env) {
    executeJruby { ScriptingContainer jruby ->
      jruby.environment.putAll(env)
      jruby.currentDirectory = pwd
      jruby.argv = args.toList().toArray()
      jruby.runScriptlet(PathType.ABSOLUTE, bundleBin)
    }
  }

  /**
   * Installs a Gem with the given version to the given path.
   * @param gem Gem Name
   * @param version Version to Install
   * @param path Path to Install to
   */
  void gem(String gem, String version, String path) {
    executeJruby { ScriptingContainer jruby ->
      jruby.currentDirectory = projectDir
      jruby.runScriptlet(
        "require 'rubygems/commands/install_command'\n" +
          "cmd = Gem::Commands::InstallCommand.new\n" +
          "cmd.handle_options [\"--no-ri\", \"--no-rdoc\", '${gem}', '-v', '${version}', '-i', '${path}']\n" +
          "begin \n" +
          "  cmd.execute\n" +
          "rescue Gem::SystemExitException => e\n" +
          "  raise e unless e.exit_code == 0\n" +
          "end"
      )
    }
  }

  /**
   * Executes RSpec for a given plugin.
   * @param plugin Plugin to run specs for
   * @param args CLI arguments to pass to rspec
   */
  void rake(String task) {
    executeJruby { ScriptingContainer jruby ->
      jruby.currentDirectory = projectDir
      jruby.runScriptlet("require 'rake'")
      jruby.runScriptlet(
        "rake = Rake.application\n" +
          "rake.init\n" +
          "rake.load_rakefile\n" +
          "rake['${task}'].invoke"
      )
    }
  }

  /**
   * Executes Closure using a fresh JRuby environment, safely tearing it down afterwards.
   * @param block Closure to run
   */
  Object executeJruby(Closure<?> block) {
    def jruby = new ScriptingContainer()
    def env = jruby.environment
    def gemDir = "${projectDir}/vendor/bundle/jruby/2.5.0".toString()
    env.put "USE_RUBY", "1"
    env.put "GEM_HOME", gemDir
    env.put "GEM_SPEC_CACHE", "${buildDir}/cache".toString()
    env.put "GEM_PATH", gemDir
    try {
      return block(jruby)
    } finally {
      jruby.terminate()
      Ruby.clearGlobalRuntime()
    }
  }
}

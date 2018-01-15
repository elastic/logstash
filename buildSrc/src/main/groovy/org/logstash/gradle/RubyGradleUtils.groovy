package org.logstash.gradle

import org.jruby.Ruby
import org.jruby.embed.ScriptingContainer

final class RubyGradleUtils {

  private final File buildDir

  private final File projectDir

  RubyGradleUtils(File buildDir, File projectDir) {
    this.buildDir = buildDir
    this.projectDir = projectDir
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
    def gemDir = "${projectDir}/bundle/jruby/2.3.0".toString()
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

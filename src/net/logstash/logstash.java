/* This is the runner for logstash when it is packed up in a jar file. 
 * It exists to work around http://jira.codehaus.org/browse/JRUBY-6015
 */
package net.logstash;
import org.jruby.embed.ScriptingContainer;
import org.jruby.embed.PathType;
import org.jruby.CompatVersion;
import java.io.InputStream;

public class logstash {
  private ScriptingContainer container;

  public static void main(String[] args) {
    // Malkovich malkovich? Malkovich!
    logstash logstash = new logstash();
    logstash.run(args);
  } /* void main */


  public logstash() {
    this.container = new ScriptingContainer();
    this.container.setCompatVersion(CompatVersion.RUBY1_9);
  }

  public void run(String[] args) {
    final String script_path = "logstash/runner.rb";
    ClassLoader loader = this.getClass().getClassLoader();
    InputStream script = loader.getResourceAsStream(script_path);
    //container.runScriptlet(PathType.RELATIVE, "logstash/runner.rb");
    this.container.setArgv(args);
    this.container.runScriptlet(script, script_path);
  }
}


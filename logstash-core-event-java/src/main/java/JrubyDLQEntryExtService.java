import org.jruby.Ruby;
import org.jruby.runtime.load.BasicLibraryService;
import org.logstash.ext.JrubyDLQEntryExtLibrary;

import java.io.IOException;

public class JrubyDLQEntryExtService implements BasicLibraryService {
    public boolean basicLoad(final Ruby runtime)
        throws IOException
    {
        new JrubyDLQEntryExtLibrary().load(runtime, false);
        return true;
    }
}

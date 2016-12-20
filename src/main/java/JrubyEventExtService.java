import org.logstash.ext.JrubyEventExtLibrary;
import org.jruby.Ruby;
import org.jruby.runtime.load.BasicLibraryService;

import java.io.IOException;

public class JrubyEventExtService implements BasicLibraryService {
    public boolean basicLoad(final Ruby runtime)
        throws IOException
    {
        new JrubyEventExtLibrary().load(runtime, false);
        return true;
    }
}

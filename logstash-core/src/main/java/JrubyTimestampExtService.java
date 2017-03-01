import org.logstash.ext.JrubyTimestampExtLibrary;
import org.jruby.Ruby;
import org.jruby.runtime.load.BasicLibraryService;

import java.io.IOException;

public class JrubyTimestampExtService implements BasicLibraryService {
    public boolean basicLoad(final Ruby runtime)
            throws IOException
    {
        new JrubyTimestampExtLibrary().load(runtime, false);
        return true;
    }
}

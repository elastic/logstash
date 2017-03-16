import org.jruby.Ruby;
import org.jruby.runtime.load.BasicLibraryService;
import org.logstash.ackedqueue.ext.JrubyAckedBatchExtLibrary;

import java.io.IOException;

public class JrubyAckedBatchExtService implements BasicLibraryService {
    public boolean basicLoad(final Ruby runtime)
            throws IOException
    {
        new JrubyAckedBatchExtLibrary().load(runtime, false);
        return true;
    }
}

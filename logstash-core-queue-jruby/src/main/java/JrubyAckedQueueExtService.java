import org.jruby.Ruby;
import org.jruby.runtime.load.BasicLibraryService;
import org.logstash.ackedqueue.ext.JrubyAckedQueueExtLibrary;
import org.logstash.ackedqueue.ext.JrubyAckedQueueMemoryExtLibrary;

import java.io.IOException;

public class JrubyAckedQueueExtService implements BasicLibraryService {
    public boolean basicLoad(final Ruby runtime)
            throws IOException
    {
        new JrubyAckedQueueExtLibrary().load(runtime, false);
        new JrubyAckedQueueMemoryExtLibrary().load(runtime, false);
        return true;
    }
}

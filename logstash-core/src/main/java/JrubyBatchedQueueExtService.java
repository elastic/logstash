import org.jruby.Ruby;
import org.jruby.runtime.load.BasicLibraryService;
import org.logstash.batchedqueue.ext.JrubyBatchedQueueExtLibrary;

import java.io.IOException;

public class JrubyBatchedQueueExtService implements BasicLibraryService {
    public boolean basicLoad(final Ruby runtime)
            throws IOException
    {
        new JrubyBatchedQueueExtLibrary().load(runtime, false);
         return true;
    }
}

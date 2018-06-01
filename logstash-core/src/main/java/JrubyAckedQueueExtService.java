import java.io.IOException;
import org.jruby.Ruby;
import org.jruby.runtime.load.BasicLibraryService;
import org.logstash.ackedqueue.ext.JrubyAckedQueueExtLibrary;

public class JrubyAckedQueueExtService implements BasicLibraryService {
    public boolean basicLoad(final Ruby runtime)
            throws IOException
    {
        new JrubyAckedQueueExtLibrary().load(runtime, false);
        return true;
    }
}

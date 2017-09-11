import org.jruby.Ruby;
import org.jruby.runtime.load.BasicLibraryService;
import org.logstash.ackedqueue.ext.JrubyAckedQueueExtLibrary;
import org.logstash.ackedqueue.ext.JrubyAckedQueueMemoryExtLibrary;

public final class JrubyAckedQueueExtService implements BasicLibraryService {
    @Override
    public boolean basicLoad(final Ruby runtime) {
        new JrubyAckedQueueExtLibrary().load(runtime, false);
        new JrubyAckedQueueMemoryExtLibrary().load(runtime, false);
        return true;
    }
}

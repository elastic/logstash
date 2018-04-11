package org.logstash.execution.codecs;

import org.logstash.execution.Codec;
import org.logstash.execution.LsConfiguration;
import org.logstash.execution.LsContext;

import java.lang.reflect.Constructor;
import java.util.concurrent.ConcurrentHashMap;

public class CodecFactory {

    // eagerly initialize singleton
    private static final CodecFactory INSTANCE;

    private ConcurrentHashMap<String, Class> codecMap = new ConcurrentHashMap<>();

    // not necessary after DiscoverPlugins is implemented
    static {
        INSTANCE = new CodecFactory();
        INSTANCE.addCodec("line", Line.class);
    }

    private CodecFactory() {
        // singleton class
    }

    public static CodecFactory getInstance() {
        return INSTANCE;
    }

    public void addCodec(String name, Class codecClass) {
        codecMap.put(name, codecClass);
    }

    public Codec getCodec(String name, LsConfiguration configuration, LsContext context) {
        if (name != null && codecMap.containsKey(name)) {
            return instantiateCodec(codecMap.get(name), configuration, context);
        }
        return null;
    }

    private Codec instantiateCodec(Class clazz, LsConfiguration configuration, LsContext context) {
        try {
            Constructor<Codec> constructor = clazz.getConstructor(LsConfiguration.class, LsContext.class);
            return constructor.newInstance(configuration, context);
        } catch (Exception e) {
            throw new IllegalStateException("Unable to instantiate codec", e);
        }
    }
}

package org.logstash.plugins.discovery;

import java.util.List;

/**
 *
 */
public interface MetadataAdapter<C> {

    //
    String getClassName(final C cls);

    String getSuperclassName(final C cls);

    List<String> getInterfacesNames(final C cls);

    List<String> getClassAnnotationNames(final C aClass);

    C getOfCreateClassObject(Vfs.File file) throws Exception;

    boolean acceptsInput(String file);

}

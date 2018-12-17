package org.logstash.plugins.discovery;

import java.lang.annotation.Annotation;
import java.util.ArrayList;
import java.util.List;

/** */
public final class JavaReflectionAdapter implements MetadataAdapter<Class> {

    public List<String> getClassAnnotationNames(Class aClass) {
        return getAnnotationNames(aClass.getDeclaredAnnotations());
    }

    public Class getOfCreateClassObject(Vfs.File file) {
        return getOfCreateClassObject(file, null);
    }

    public Class getOfCreateClassObject(Vfs.File file, ClassLoader... loaders) {
        String name = file.getRelativePath().replace("/", ".").replace(".class", "");
        return ReflectionUtils.forName(name, loaders);
    }

    public String getClassName(Class cls) {
        return cls.getName();
    }

    public String getSuperclassName(Class cls) {
        Class superclass = cls.getSuperclass();
        return superclass != null ? superclass.getName() : "";
    }

    public List<String> getInterfacesNames(Class cls) {
        Class[] classes = cls.getInterfaces();
        List<String> names = new ArrayList<>(classes != null ? classes.length : 0);
        if (classes != null) {
            for (Class cls1 : classes) names.add(cls1.getName());
        }
        return names;
    }

    public boolean acceptsInput(String file) {
        return file.endsWith(".class");
    }

    //
    private List<String> getAnnotationNames(Annotation[] annotations) {
        List<String> names = new ArrayList<>(annotations.length);
        for (Annotation annotation : annotations) {
            names.add(annotation.annotationType().getName());
        }
        return names;
    }

    public static String getName(Class type) {
        if (type.isArray()) {
            try {
                Class cl = type;
                int dim = 0;
                while (cl.isArray()) {
                    dim++;
                    cl = cl.getComponentType();
                }
                return cl.getName() + Utils.repeat("[]", dim);
            } catch (Throwable e) {
                //
            }
        }
        return type.getName();
    }
}

package org.logstash.plugins.discovery;

import com.google.common.collect.Lists;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

@SuppressWarnings("unchecked")
public abstract class ReflectionUtils {


    public static boolean includeObject;

    /**
     * get the immediate supertype and interfaces of the given {@code type}
     */
    public static Set<Class<?>> getSuperTypes(Class<?> type) {
        Set<Class<?>> result = new LinkedHashSet<>();
        Class<?> superclass = type.getSuperclass();
        Class<?>[] interfaces = type.getInterfaces();
        if (superclass != null && (includeObject || !superclass.equals(Object.class))) {
            result.add(superclass);
        }
        if (interfaces != null && interfaces.length > 0) {
            result.addAll(Arrays.asList(interfaces));
        }
        return result;
    }

    //predicates

    public static Class<?> forName(String typeName, ClassLoader... classLoaders) {
        if (getPrimitiveNames().contains(typeName)) {
            return getPrimitiveTypes().get(getPrimitiveNames().indexOf(typeName));
        } else {
            String type;
            if (typeName.contains("[")) {
                int i = typeName.indexOf("[");
                type = typeName.substring(0, i);
                String array = typeName.substring(i).replace("]", "");

                if (getPrimitiveNames().contains(type)) {
                    type = getPrimitiveDescriptors().get(getPrimitiveNames().indexOf(type));
                } else {
                    type = "L" + type + ";";
                }

                type = array + type;
            } else {
                type = typeName;
            }

            List<ReflectionsException> reflectionsExceptions = Lists.newArrayList();
            for (ClassLoader classLoader : ClasspathHelper.classLoaders(classLoaders)) {
                if (type.contains("[")) {
                    try {
                        return Class.forName(type, false, classLoader);
                    } catch (Throwable e) {
                        reflectionsExceptions.add(new ReflectionsException("could not get type for name " + typeName, e));
                    }
                }
                try {
                    return classLoader.loadClass(type);
                } catch (Throwable e) {
                    reflectionsExceptions.add(new ReflectionsException("could not get type for name " + typeName, e));
                }
            }
            return null;
        }
    }

    /**
     * try to resolve all given string representation of types to a list of java types
     */
    public static <T> List<Class<? extends T>> forNames(final Iterable<String> classes, ClassLoader... classLoaders) {
        List<Class<? extends T>> result = new ArrayList<>();
        for (String className : classes) {
            Class<?> type = forName(className, classLoaders);
            if (type != null) {
                result.add((Class<? extends T>) type);
            }
        }
        return result;
    }

    //
    private static List<String> primitiveNames;
    private static List<Class> primitiveTypes;
    private static List<String> primitiveDescriptors;

    private static void initPrimitives() {
        if (primitiveNames == null) {
            primitiveNames = Lists.newArrayList("boolean", "char", "byte", "short", "int", "long", "float", "double", "void");
            primitiveTypes = Lists.newArrayList(boolean.class, char.class, byte.class, short.class, int.class, long.class, float.class, double.class, void.class);
            primitiveDescriptors = Lists.newArrayList("Z", "C", "B", "S", "I", "J", "F", "D", "V");
        }
    }

    private static List<String> getPrimitiveNames() {
        initPrimitives();
        return primitiveNames;
    }

    private static List<Class> getPrimitiveTypes() {
        initPrimitives();
        return primitiveTypes;
    }

    private static List<String> getPrimitiveDescriptors() {
        initPrimitives();
        return primitiveDescriptors;
    }

}

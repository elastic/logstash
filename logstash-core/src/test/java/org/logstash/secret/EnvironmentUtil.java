package org.logstash.secret;

import java.lang.reflect.Field;
import java.util.Collections;
import java.util.Map;

/**
 * Tool to change the in-memory environment settings, does not change actual environment
 */
public class EnvironmentUtil {

    //near exact copy from https://stackoverflow.com/questions/318239/how-do-i-set-environment-variables-from-java
    //thanks @pushy and @Edward Campbell !
    @SuppressWarnings("unchecked")
    private static void setEnv(Map<String, String> newenv, String removeKey) throws Exception {
        try {
            Class<?> processEnvironmentClass = Class.forName("java.lang.ProcessEnvironment");
            Field theEnvironmentField = processEnvironmentClass.getDeclaredField("theEnvironment");
            theEnvironmentField.setAccessible(true);
            Map<String, String> env = (Map<String, String>) theEnvironmentField.get(null);
            if(removeKey == null){
                env.putAll(newenv);
            }else{
                env.remove(removeKey);
            }
            Field theCaseInsensitiveEnvironmentField = processEnvironmentClass.getDeclaredField("theCaseInsensitiveEnvironment");
            theCaseInsensitiveEnvironmentField.setAccessible(true);
            Map<String, String> cienv = (Map<String, String>) theCaseInsensitiveEnvironmentField.get(null);
            if(removeKey == null){
                cienv.putAll(newenv);
            }else{
                cienv.remove(removeKey);
            }
        } catch (NoSuchFieldException e) {
            Class[] classes = Collections.class.getDeclaredClasses();
            Map<String, String> env = System.getenv();
            for (Class cl : classes) {
                if ("java.util.Collections$UnmodifiableMap".equals(cl.getName())) {
                    Field field = cl.getDeclaredField("m");
                    field.setAccessible(true);
                    Object obj = field.get(env);
                    Map<String, String> map = (Map<String, String>) obj;
                    map.clear();
                    if(removeKey == null){
                        map.putAll(newenv);
                    }else{
                        map.remove(removeKey);
                    }
                }
            }
        }
    }

    public static void add(Map<String, String> environment) throws Exception {
        setEnv(environment, null);
    }

    public static void remove(String key) throws Exception {
        setEnv(null, key);
    }
}

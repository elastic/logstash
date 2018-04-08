package org.logstash;

import org.logstash.LogstashAPI.Filter;
import org.logstash.LogstashAPI.Input;
import org.logstash.LogstashAPI.Output;
import org.logstash.LogstashAPI.Plugin;
import org.reflections.Reflections;
import org.reflections.scanners.FieldAnnotationsScanner;
import org.reflections.scanners.SubTypesScanner;
import org.reflections.scanners.TypeAnnotationsScanner;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.net.URL;
import java.net.URLClassLoader;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

public class DefaultPluginManager {

    Map<URLClassLoader, Class<Input>> _inputs = new HashMap<>();
    Map<URLClassLoader, Class<Filter>> _filters = new HashMap<>();
    Map<URLClassLoader, Class<Output>> _outputs = new HashMap<>();

    Collection<Input> inputs = new HashSet<>();
    Collection<Filter> filters = new HashSet<>();
    Collection<Output> outputs = new HashSet<>();

    Path pluginsPath;

    public DefaultPluginManager(Path pluginsPath) {
        System.out.println("Plugin path: " + pluginsPath.toString());
        this.pluginsPath = pluginsPath;
    }


    public Collection<Input> getInputs() {

        if(inputs.isEmpty()) {
            inputs = newUp(_inputs);
        }
        return inputs;

    }

    public Collection<Filter> getFilters() {
        if(filters.isEmpty()) {
            filters = newUp(_filters);
        }
        return filters;
    }

    public Collection<Output> getOutputs() {
        if(outputs.isEmpty()) {
            outputs = newUp(_outputs);
        }
        return outputs;
    }

    private <T> Collection<T> newUp(Map<URLClassLoader, Class <T>> clazzes){
       return  clazzes.entrySet().stream().map(entry -> {
            try {
                return (T)entry.getKey().loadClass(entry.getValue().getCanonicalName()).newInstance();
            } catch (Exception e) {
                throw new RuntimeException(e);
            }
        }).collect(Collectors.toList());
    }

    public void start() {
        System.out.println("Starting plugin manager");
        System.out.println("Starting to unzip");
        unzip(findFiles(pluginsPath.toFile(), "zip"));
        loadPlugins(pluginsPath.toFile());

        System.out.println("Finished unzip");

    }

    void shutdown() {
        System.out.println("Stopping plugin manager");
    }

    private void unzip(Collection<File> zips) {
        for (File zip : zips) {
            pluginsPath.resolve(zip.getName().replace(".zip", "")).toFile().mkdirs();
            try {
                byte[] buffer = new byte[1024];
                ZipInputStream zis = new ZipInputStream(new FileInputStream(zip));
                try {
                    ZipEntry zipEntry = zis.getNextEntry();
                    while (zipEntry != null) {
                        File outfile = pluginsPath.resolve(zip.getName().replace(".zip", "")).resolve(zipEntry.getName()).toFile();
                        System.out.println("Outfile: " + outfile);
                        if (zipEntry.isDirectory()) {
                            outfile.mkdirs();
                            zipEntry = zis.getNextEntry();
                        } else {

                            try (FileOutputStream fos = new FileOutputStream(outfile)) {
                                int len;
                                while ((len = zis.read(buffer)) > 0) {
                                    fos.write(buffer, 0, len);
                                }
                                zipEntry = zis.getNextEntry();
                            }
                        }
                    }
                } finally {
                    zis.closeEntry();
                    zis.close();
                }
            } catch (Exception e) {
                throw new RuntimeException(e);
            }
        }
    }

    private Collection<File> findFiles(File base, String extension) {
        List<File> files = new ArrayList<>(Arrays.asList(base.listFiles()));
        return files.stream().filter(f -> f.isFile()).filter(f -> f.getName().endsWith((extension))).collect(Collectors.toList());
    }

    private void loadPlugins(File base) {
        try {
            List<File> dirs = Arrays.asList(base.listFiles()).stream().filter(f -> f.isDirectory()).collect(Collectors.toList());

            for (File dir : dirs) {
                URL[] urlsToLoad = new URL[2];
                //add classes
                urlsToLoad[0] = dir.toPath().resolve("classes").toUri().toURL();
                urlsToLoad[1] = dir.toPath().resolve("lib").toUri().toURL();


                URLClassLoader pluginLoader = URLClassLoader.newInstance(urlsToLoad, this.getClass().getClassLoader());

                System.out.println("*******Classpath (" + dir + ") *********");
                Arrays.asList(urlsToLoad).forEach(System.out::println);
                System.out.println("****************");

                //Find plugin via reflections
                Reflections reflections = new Reflections("org.logstash.plugins", new SubTypesScanner(), new TypeAnnotationsScanner(), new FieldAnnotationsScanner(), pluginLoader);
                Set<Class<?>> plugins = reflections.getTypesAnnotatedWith(Plugin.class);

                for (Class<?> clazz : plugins) {
                    Class<?>[] interfaces = clazz.getInterfaces();
                   Plugin plugin = clazz.getAnnotation(Plugin.class);
                    String type = null;
                    for (Class<?> i : interfaces) {
                        if ("org.logstash.LogstashAPI.Input".equals(i.getCanonicalName())) {
                            _inputs.put(pluginLoader, (Class<Input>) clazz);
                            type = "input";
                        } else if ("org.logstash.LogstashAPI.Output".equals(i.getCanonicalName())) {
                            _outputs.put(pluginLoader, (Class<Output>) clazz);
                            type = "output";
                        } else if ("org.logstash.LogstashAPI.Filter".equals(i.getCanonicalName())) {
                            _filters.put(pluginLoader, (Class<Filter>) clazz);
                            type = "filter";

                        }
                        System.out.println("Found " + type + " plugin \"" + plugin.value() + "\"");
                    }
                }
            }

        } catch (Exception e) {
            throw new RuntimeException(e);
        }


    }
}

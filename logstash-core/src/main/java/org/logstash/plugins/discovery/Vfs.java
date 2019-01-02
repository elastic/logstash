package org.logstash.plugins.discovery;

import com.google.common.base.Predicate;
import com.google.common.collect.AbstractIterator;
import com.google.common.collect.Lists;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.net.JarURLConnection;
import java.net.MalformedURLException;
import java.net.URISyntaxException;
import java.net.URL;
import java.net.URLConnection;
import java.net.URLDecoder;
import java.util.Collections;
import java.util.Enumeration;
import java.util.List;
import java.util.Stack;
import java.util.jar.JarFile;
import java.util.jar.JarInputStream;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.zip.ZipEntry;

public abstract class Vfs {
    private static List<Vfs.UrlType> defaultUrlTypes = Lists.newArrayList(Vfs.DefaultUrlTypes.values());

    /**
     * an abstract vfs dir
     */
    public interface Dir {
        String getPath();

        Iterable<Vfs.File> getFiles();

        void close();
    }

    /**
     * an abstract vfs file
     */
    public interface File {
        String getName();

        String getRelativePath();

        InputStream openInputStream() throws IOException;
    }

    /**
     * a matcher and factory for a url
     */
    public interface UrlType {
        boolean matches(URL url) throws Exception;

        Vfs.Dir createDir(URL url) throws Exception;
    }

    /**
     * @param url URL from which to create a Dir
     * @return Dir created from the given url, using the defaultUrlTypes
     */
    public static Vfs.Dir fromURL(final URL url) {
        return fromURL(url, defaultUrlTypes);
    }

    /**
     * @param url URL from which to create a Dir
     * @param urlTypes given URL types
     * @return Dir created from the given url, using the given urlTypes
     */
    public static Vfs.Dir fromURL(final URL url, final List<Vfs.UrlType> urlTypes) {
        for (final Vfs.UrlType type : urlTypes) {
            try {
                if (type.matches(url)) {
                    final Vfs.Dir dir = type.createDir(url);
                    if (dir != null) {
                        return dir;
                    }
                }
            } catch (final Throwable e) {
            }
        }

        throw new ReflectionsException("could not create Vfs.Dir from url, no matching UrlType was found [" + url.toExternalForm() + "]\n" +
            "either use fromURL(final URL url, final List<UrlType> urlTypes) or " +
            "use the static setDefaultURLTypes(final List<UrlType> urlTypes) or addDefaultURLTypes(UrlType urlType) " +
            "with your specialized UrlType.");
    }

    /**
     * @param url provided URL
     * @return {@link Vfs.File} from provided URL
     */
    public static java.io.File getFile(final URL url) {
        java.io.File file;
        String path;

        try {
            path = url.toURI().getSchemeSpecificPart();
            if ((file = new java.io.File(path)).exists()) {
                return file;
            }
        } catch (final URISyntaxException e) {
        }

        try {
            path = URLDecoder.decode(url.getPath(), "UTF-8");
            if (path.contains(".jar!")) {
                path = path.substring(0, path.lastIndexOf(".jar!") + ".jar".length());
            }
            if ((file = new java.io.File(path)).exists()) {
                return file;
            }

        } catch (final UnsupportedEncodingException e) {
        }

        try {
            path = url.toExternalForm();
            if (path.startsWith("jar:")) {
                path = path.substring("jar:".length());
            }
            if (path.startsWith("wsjar:")) {
                path = path.substring("wsjar:".length());
            }
            if (path.startsWith("file:")) {
                path = path.substring("file:".length());
            }
            if (path.contains(".jar!")) {
                path = path.substring(0, path.indexOf(".jar!") + ".jar".length());
            }
            if ((file = new java.io.File(path)).exists()) {
                return file;
            }

            path = path.replace("%20", " ");
            if ((file = new java.io.File(path)).exists()) {
                return file;
            }

        } catch (final Exception e) {
        }

        return null;
    }

    private static boolean hasJarFileInPath(final URL url) {
        return url.toExternalForm().matches(".*\\.jar(\\!.*|$)");
    }

    public enum DefaultUrlTypes implements Vfs.UrlType {
        jarFile {
            @Override
            public boolean matches(final URL url) {
                return url.getProtocol().equals("file") && hasJarFileInPath(url);
            }

            @Override
            public Vfs.Dir createDir(final URL url) throws Exception {
                return new Vfs.ZipDir(new JarFile(getFile(url)));
            }
        },

        jarUrl {
            @Override
            public boolean matches(final URL url) {
                return "jar".equals(url.getProtocol()) || "zip".equals(url.getProtocol()) || "wsjar".equals(url.getProtocol());
            }

            @Override
            public Vfs.Dir createDir(final URL url) throws Exception {
                try {
                    final URLConnection urlConnection = url.openConnection();
                    if (urlConnection instanceof JarURLConnection) {
                        return new Vfs.ZipDir(((JarURLConnection) urlConnection).getJarFile());
                    }
                } catch (final Throwable e) { /*fallback*/ }
                final java.io.File file = getFile(url);
                if (file != null) {
                    return new Vfs.ZipDir(new JarFile(file));
                }
                return null;
            }
        },

        directory {
            @Override
            public boolean matches(final URL url) {
                if (url.getProtocol().equals("file") && !hasJarFileInPath(url)) {
                    final java.io.File file = getFile(url);
                    return file != null && file.isDirectory();
                } else {
                    return false;
                }
            }

            @Override
            public Vfs.Dir createDir(final URL url) {
                return new Vfs.SystemDir(getFile(url));
            }
        },

        jboss_vfs {
            @Override
            public boolean matches(final URL url) {
                return url.getProtocol().equals("vfs");
            }

            @Override
            public Vfs.Dir createDir(final URL url) throws Exception {
                final Object content = url.openConnection().getContent();
                final Class<?> virtualFile = ClasspathHelper.contextClassLoader().loadClass("org.jboss.vfs.VirtualFile");
                final java.io.File physicalFile = (java.io.File) virtualFile.getMethod("getPhysicalFile").invoke(content);
                final String name = (String) virtualFile.getMethod("getName").invoke(content);
                java.io.File file = new java.io.File(physicalFile.getParentFile(), name);
                if (!file.exists() || !file.canRead()) {
                    file = physicalFile;
                }
                return file.isDirectory() ? new Vfs.SystemDir(file) : new Vfs.ZipDir(new JarFile(file));
            }
        },

        jboss_vfsfile {
            @Override
            public boolean matches(final URL url) {
                return "vfszip".equals(url.getProtocol()) || "vfsfile".equals(url.getProtocol());
            }

            @Override
            public Vfs.Dir createDir(final URL url) {
                return new Vfs.UrlTypeVFS().createDir(url);
            }
        },

        bundle {
            @Override
            public boolean matches(final URL url) {
                return url.getProtocol().startsWith("bundle");
            }

            @Override
            public Vfs.Dir createDir(final URL url) throws Exception {
                return fromURL((URL) ClasspathHelper.contextClassLoader().
                    loadClass("org.eclipse.core.runtime.FileLocator").getMethod("resolve", URL.class).invoke(null, url));
            }
        },

        jarInputStream {
            @Override
            public boolean matches(final URL url) {
                return url.toExternalForm().contains(".jar");
            }

            @Override
            public Vfs.Dir createDir(final URL url) {
                return new Vfs.JarInputDir(url);
            }
        }
    }

    private static final class JarInputDir implements Vfs.Dir {
        private final URL url;
        JarInputStream jarInputStream;
        long cursor;
        long nextCursor;

        public JarInputDir(final URL url) {
            this.url = url;
        }

        @Override
        public String getPath() {
            return url.getPath();
        }

        @Override
        public Iterable<Vfs.File> getFiles() {
            return () -> new AbstractIterator<Vfs.File>() {

                {
                    try {
                        jarInputStream = new JarInputStream(url.openConnection().getInputStream());
                    } catch (final Exception e) {
                        throw new ReflectionsException("Could not open url connection", e);
                    }
                }

                @Override
                protected Vfs.File computeNext() {
                    while (true) {
                        try {
                            final ZipEntry entry = jarInputStream.getNextJarEntry();
                            if (entry == null) {
                                return endOfData();
                            }

                            long size = entry.getSize();
                            if (size < 0) {
                                size = 0xffffffffl + size; //JDK-6916399
                            }
                            nextCursor += size;
                            if (!entry.isDirectory()) {
                                return new Vfs.JarInputFile(entry, Vfs.JarInputDir.this, cursor, nextCursor);
                            }
                        } catch (final IOException e) {
                            throw new ReflectionsException("could not get next zip entry", e);
                        }
                    }
                }
            };
        }

        @Override
        public void close() {
            Utils.close(jarInputStream);
        }
    }

    public static class JarInputFile implements Vfs.File {
        private final ZipEntry entry;
        private final Vfs.JarInputDir jarInputDir;
        private final long fromIndex;
        private final long endIndex;

        public JarInputFile(final ZipEntry entry, final Vfs.JarInputDir jarInputDir, final long cursor, final long nextCursor) {
            this.entry = entry;
            this.jarInputDir = jarInputDir;
            fromIndex = cursor;
            endIndex = nextCursor;
        }

        @Override
        public String getName() {
            final String name = entry.getName();
            return name.substring(name.lastIndexOf("/") + 1);
        }

        @Override
        public String getRelativePath() {
            return entry.getName();
        }

        @Override
        public InputStream openInputStream() {
            return new InputStream() {
                @Override
                public int read() throws IOException {
                    if (jarInputDir.cursor >= fromIndex && jarInputDir.cursor <= endIndex) {
                        final int read = jarInputDir.jarInputStream.read();
                        jarInputDir.cursor++;
                        return read;
                    } else {
                        return -1;
                    }
                }
            };
        }
    }

    public static final class ZipDir implements Vfs.Dir {
        final java.util.zip.ZipFile jarFile;

        public ZipDir(final JarFile jarFile) {
            this.jarFile = jarFile;
        }

        @Override
        public String getPath() {
            return jarFile.getName();
        }

        @Override
        public Iterable<Vfs.File> getFiles() {
            return () -> new AbstractIterator<Vfs.File>() {
                final Enumeration<? extends ZipEntry> entries = jarFile.entries();

                @Override
                protected Vfs.File computeNext() {
                    while (entries.hasMoreElements()) {
                        final ZipEntry entry = entries.nextElement();
                        if (!entry.isDirectory()) {
                            return new Vfs.ZipFile(Vfs.ZipDir.this, entry);
                        }
                    }

                    return endOfData();
                }
            };
        }

        @Override
        public void close() {
            try {
                jarFile.close();
            } catch (final IOException e) {
            }
        }

        @Override
        public String toString() {
            return jarFile.getName();
        }
    }

    public static final class ZipFile implements Vfs.File {
        private final Vfs.ZipDir root;
        private final ZipEntry entry;

        public ZipFile(final Vfs.ZipDir root, final ZipEntry entry) {
            this.root = root;
            this.entry = entry;
        }

        @Override
        public String getName() {
            final String name = entry.getName();
            return name.substring(name.lastIndexOf("/") + 1);
        }

        @Override
        public String getRelativePath() {
            return entry.getName();
        }

        @Override
        public InputStream openInputStream() throws IOException {
            return root.jarFile.getInputStream(entry);
        }

        @Override
        public String toString() {
            return root.getPath() + "!" + java.io.File.separatorChar + entry.toString();
        }
    }

    public static final class SystemDir implements Vfs.Dir {
        private final java.io.File file;

        public SystemDir(final java.io.File file) {
            if (file != null && (!file.isDirectory() || !file.canRead())) {
                throw new RuntimeException("cannot use dir " + file);
            }

            this.file = file;
        }

        @Override
        public String getPath() {
            if (file == null) {
                return "/NO-SUCH-DIRECTORY/";
            }
            return file.getPath().replace("\\", "/");
        }

        @Override
        public Iterable<Vfs.File> getFiles() {
            if (file == null || !file.exists()) {
                return Collections.emptyList();
            }
            return () -> new AbstractIterator<Vfs.File>() {
                final Stack<java.io.File> stack = new Stack<>();

                {
                    stack.addAll(listFiles(file));
                }

                @Override
                protected Vfs.File computeNext() {
                    while (!stack.isEmpty()) {
                        final java.io.File file = stack.pop();
                        if (file.isDirectory()) {
                            stack.addAll(listFiles(file));
                        } else {
                            return new Vfs.SystemFile(Vfs.SystemDir.this, file);
                        }
                    }

                    return endOfData();
                }
            };
        }

        private static List<java.io.File> listFiles(final java.io.File file) {
            final java.io.File[] files = file.listFiles();

            if (files != null) {
                return Lists.newArrayList(files);
            } else {
                return Lists.newArrayList();
            }
        }

        @Override
        public void close() {
        }

        @Override
        public String toString() {
            return getPath();
        }
    }

    private static final class UrlTypeVFS implements Vfs.UrlType {
        public static final String[] REPLACE_EXTENSION = {".ear/", ".jar/", ".war/", ".sar/", ".har/", ".par/"};

        final String VFSZIP = "vfszip";
        final String VFSFILE = "vfsfile";

        @Override
        public boolean matches(final URL url) {
            return VFSZIP.equals(url.getProtocol()) || VFSFILE.equals(url.getProtocol());
        }

        @Override
        public Vfs.Dir createDir(final URL url) {
            try {
                final URL adaptedUrl = adaptURL(url);
                return new Vfs.ZipDir(new JarFile(adaptedUrl.getFile()));
            } catch (final Exception e) {
                try {
                    return new Vfs.ZipDir(new JarFile(url.getFile()));
                } catch (final IOException e1) {
                }
            }
            return null;
        }

        public URL adaptURL(final URL url) throws MalformedURLException {
            if (VFSZIP.equals(url.getProtocol())) {
                return replaceZipSeparators(url.getPath(), realFile);
            } else if (VFSFILE.equals(url.getProtocol())) {
                return new URL(url.toString().replace(VFSFILE, "file"));
            } else {
                return url;
            }
        }

        URL replaceZipSeparators(final String path, final Predicate<java.io.File> acceptFile)
            throws MalformedURLException {
            int pos = 0;
            while (pos != -1) {
                pos = findFirstMatchOfDeployableExtention(path, pos);

                if (pos > 0) {
                    final java.io.File file = new java.io.File(path.substring(0, pos - 1));
                    if (acceptFile.apply(file)) {
                        return replaceZipSeparatorStartingFrom(path, pos);
                    }
                }
            }

            throw new ReflectionsException("Unable to identify the real zip file in path '" + path + "'.");
        }

        int findFirstMatchOfDeployableExtention(final String path, final int pos) {
            final Pattern p = Pattern.compile("\\.[ejprw]ar/");
            final Matcher m = p.matcher(path);
            if (m.find(pos)) {
                return m.end();
            } else {
                return -1;
            }
        }

        Predicate<java.io.File> realFile = file -> file.exists() && file.isFile();

        URL replaceZipSeparatorStartingFrom(final String path, final int pos)
            throws MalformedURLException {
            final String zipFile = path.substring(0, pos - 1);
            String zipPath = path.substring(pos);

            int numSubs = 1;
            for (final String ext : REPLACE_EXTENSION) {
                while (zipPath.contains(ext)) {
                    zipPath = zipPath.replace(ext, ext.substring(0, 4) + "!");
                    numSubs++;
                }
            }

            String prefix = "";
            for (int i = 0; i < numSubs; i++) {
                prefix += "zip:";
            }

            if (zipPath.trim().length() == 0) {
                return new URL(prefix + "/" + zipFile);
            } else {
                return new URL(prefix + "/" + zipFile + "!" + zipPath);
            }
        }
    }

    private static final class SystemFile implements Vfs.File {
        private final Vfs.SystemDir root;
        private final java.io.File file;

        public SystemFile(final Vfs.SystemDir root, final java.io.File file) {
            this.root = root;
            this.file = file;
        }

        @Override
        public String getName() {
            return file.getName();
        }

        @Override
        public String getRelativePath() {
            final String filepath = file.getPath().replace("\\", "/");
            if (filepath.startsWith(root.getPath())) {
                return filepath.substring(root.getPath().length() + 1);
            }

            return null; //should not get here
        }

        @Override
        public InputStream openInputStream() {
            try {
                return new FileInputStream(file);
            } catch (final FileNotFoundException e) {
                throw new RuntimeException(e);
            }
        }

        @Override
        public String toString() {
            return file.toString();
        }
    }
}

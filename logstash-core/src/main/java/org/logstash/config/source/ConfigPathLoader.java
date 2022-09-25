package org.logstash.config.source;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.common.IncompleteSourceWithMetadataException;
import org.logstash.common.SourceWithMetadata;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.Charset;
import java.nio.charset.CharsetDecoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.regex.Pattern;

public class ConfigPathLoader {

    private static final Logger logger = LogManager.getLogger(ConfigPathLoader.class);

    private static Pattern LOCAL_FILE_URI = Pattern.compile("^file://", Pattern.CASE_INSENSITIVE);

    private final Path path;

    public static List<SourceWithMetadata> read(String path) throws IOException, ConfigLoadingException, IncompleteSourceWithMetadataException {
        return new ConfigPathLoader(path).read();
    }

    public ConfigPathLoader(String path) {
        this.path = normalizePath(path);
    }

    private Path normalizePath(String path) {
        final String cleaned = LOCAL_FILE_URI.matcher(path).replaceAll("");
        return Paths.get(cleaned);
    }

    public List<SourceWithMetadata> read() throws IOException, ConfigLoadingException, IncompleteSourceWithMetadataException {
        if (logger.isDebugEnabled()) {
            logger.debug("Skipping the following files while reading config since they don't match the specified glob pattern file: {}",
                        getUnmatchedFiles());
        }

        final List<Path> encodingIssueFiles = new ArrayList<>();
        final List<SourceWithMetadata> configParts = new ArrayList<>();
        final List<Path> matchedFiles = getMatchedFiles();
        for (Path file : matchedFiles) {
            if (file.toFile().isDirectory()) {
                continue;
            }
            logger.debug("Reading config file {}", file);
            if (isTemporaryFile(file)) {
                logger.warn("NOT reading config file because it is a temp file {}", file);
                continue;
            }
            final byte[] rawContent = Files.readAllBytes(file);
            if (verifyEncoding(rawContent, StandardCharsets.UTF_8))  {
                final String configString = new String(rawContent, StandardCharsets.UTF_8);
                SourceWithMetadata part = new SourceWithMetadata("file", file.toString(), 0, 0, configString);
                configParts.add(part);
            } else {
                encodingIssueFiles.add(file);
            }
        }
        if (!encodingIssueFiles.isEmpty()) {
            throw new ConfigLoadingException("The following config files contains non-ascii characters but are not UTF-8 encoded " + encodingIssueFiles);
        }
        if (configParts.isEmpty()) {
            logger.info("No config files found in path {}", path);
        }
        return configParts;
    }

    private boolean verifyEncoding(byte[] rawContent, Charset charset) {
        CharsetDecoder decoder = charset.newDecoder();
        try {
            decoder.decode(ByteBuffer.wrap(rawContent));
            return true;
        } catch (CharacterCodingException ueex) {
            return false;
        }
    }

    private boolean isTemporaryFile(Path filepath) {
        return filepath.getFileName().toString().endsWith("~");
    }

    private Path getPath() {
        if (path.toFile().isDirectory()) {
            return path.resolve("*");
        }
        return path;
    }

    private List<Path> getMatchedFiles() throws IOException {
        List<Path> globMatchingPaths = GlobUtils.glob(getPath());
        Collections.sort(globMatchingPaths);
        return globMatchingPaths;
    }

    private List<Path> getUnmatchedFiles() throws IOException {
//        transform "/var/lib/*.conf" => /var/lib/*
        final Path t = path.subpath(0, path.getNameCount() - 1);
        final List<Path> allFiles = GlobUtils.glob(t.resolve("*"));
        Collections.sort(allFiles);
        allFiles.removeAll(getMatchedFiles());
        return allFiles;
    }

}

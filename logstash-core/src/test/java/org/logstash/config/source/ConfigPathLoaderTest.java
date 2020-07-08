package org.logstash.config.source;

import org.junit.Test;
import org.logstash.common.IncompleteSourceWithMetadataException;
import org.logstash.common.SourceWithMetadata;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

import static org.junit.Assert.*;

public class ConfigPathLoaderTest {

    @Test //no configs in the directory
    public void testNoConfigsInDirectory() throws IOException, ConfigLoadingException, IncompleteSourceWithMetadataException {
        final Path tempDirectory = Files.createTempDirectory("studtmp-");

        assertTrue("returns an empty array", ConfigPathLoader.read(tempDirectory.toString()).isEmpty());
    }

    @Test //no configs target file doesn't exist
    public void testNoConfigsTargetFileDoesntExists() throws IOException, ConfigLoadingException, IncompleteSourceWithMetadataException {
        final Path tempDirectory = Files.createTempDirectory("studtmp-");
        final Path notExistingFilePath = tempDirectory.resolve("ls.conf");

        assertTrue("returns an empty array", ConfigPathLoader.read(notExistingFilePath.toString()).isEmpty());
    }

    @Test //when it exist when the files have invalid encoding
    public void testConfigExistsWithInvalidEncoding() throws IOException, IncompleteSourceWithMetadataException {
        final Path tempDirectory = Files.createTempDirectory("studtmp-");
        final Path file = tempDirectory.resolve("wrong_encoding.conf");
        Files.write(file, new byte[]{(byte) 0x80});

        //check against base name because on Windows long paths are shrinked in the exception message
        try {
            ConfigPathLoader.read(tempDirectory.toString());
            fail("Must raise exception");
        } catch (ConfigLoadingException ex) {
            assertTrue("raises an exception", ex.getMessage().contains(tempDirectory.toString()));
        }
    }

    static final class ConfigFileDefinition {
        final String filename;
        final String fileContent;

        public ConfigFileDefinition(String filename, String fileContent) {
            this.filename = filename;
            this.fileContent = fileContent;
        }

        public String getFilename() {
            return filename;
        }

        public String getFileContent() {
            return fileContent;
        }
    }

    @Test //when we target one file read config from files
    public void testConfigInOneFile() throws IOException, ConfigLoadingException, IncompleteSourceWithMetadataException {
        final Path tempDirectory = Files.createTempDirectory("studtmp-");

        final ConfigFileDefinition configDefinition = new ConfigFileDefinition("config1.conf", "input1");
        List<ConfigFileDefinition> files = Collections.singletonList(configDefinition);
        Path readerConfig = tempDirectory.resolve(configDefinition.filename);

        setupConfigFiles(tempDirectory, files);

        verifyConfig(readerConfig, files, tempDirectory);
    }

    private void setupConfigFiles(Path tempDirectory, List<ConfigFileDefinition> files) throws IOException {
        setupConfigFiles(tempDirectory, files, 0);
    }

    private void setupConfigFiles(Path tempDirectory, List<ConfigFileDefinition> files, int alreadyExistingFiles) throws IOException {
        for (ConfigFileDefinition fileDef : files) {
            final Path file = Files.createFile(tempDirectory.resolve(fileDef.filename));
            Files.write(file, fileDef.fileContent.getBytes());
        }
        assertTrue(files.size() >= 1);
        assertEquals(GlobUtils.glob(tempDirectory.resolve("*")).size(), files.size() + alreadyExistingFiles);
    }

    private void verifyConfig(Path readerConfig, List<ConfigFileDefinition> files, Path directory) throws ConfigLoadingException, IOException, IncompleteSourceWithMetadataException {
        final String readerConfigStr = readerConfig.toString();

        verifyConfig(readerConfigStr, files, directory);
    }

    private void verifyConfig(String readerConfig, List<ConfigFileDefinition> files, Path directory) throws IOException, ConfigLoadingException, IncompleteSourceWithMetadataException {
        final List<SourceWithMetadata> parts = ConfigPathLoader.read(readerConfig);

        assertEquals("returns a `config_parts` per file", files.size(), parts.size());

        final List<String> partsNames = parts.stream()
                .map(SourceWithMetadata::getId)
                .map(id -> Paths.get(id))
                .map(Path::getFileName)
                .map(Path::toString)
                .collect(Collectors.toList());
        final List<String> filesNames = files.stream()
                .map(ConfigFileDefinition::getFilename)
                .sorted()
                .collect(Collectors.toList());
        assertEquals("returns alphabetically sorted parts", filesNames, partsNames);

        for (SourceWithMetadata part : parts) {
            final String basename = Paths.get(part.getId()).getFileName().toString();
            final Path filePath = directory.resolve(basename).normalize();
            final String fileContent = files.stream()
                    .filter(f -> f.getFilename().equals(basename))
                    .findFirst()
                    .get()
                    .getFileContent();
            assertThat("returns valid `config_parts`", part, MatcherUtils.beSourceWithMetadata("file", filePath.toString(), fileContent));
        }
    }

    @Test // when we target a path with multiples files
    public void testConfigFromMultipleFiles() throws IOException, ConfigLoadingException, IncompleteSourceWithMetadataException {
        final Path tempDirectory = Files.createTempDirectory("studtmp-");

        List<ConfigFileDefinition> files = Arrays.asList(
                new ConfigFileDefinition("config1.conf", "input1"),
                new ConfigFileDefinition("config2.conf", "input2"),
                new ConfigFileDefinition("config3.conf", "input3"),
                new ConfigFileDefinition("config4.conf", "input4")
        );
        Path readerConfig = tempDirectory;

        setupConfigFiles(tempDirectory, files);

        verifyConfig(readerConfig, files, tempDirectory);
    }

    @Test // when there temporary files in the directory
    public void testConfigMixedWithTemporaryFiles() throws IOException, ConfigLoadingException, IncompleteSourceWithMetadataException {
        final Path tempDirectory = Files.createTempDirectory("studtmp-");

        List<ConfigFileDefinition> files = Arrays.asList(
                new ConfigFileDefinition("config1.conf", "input1"),
                new ConfigFileDefinition("config2.conf", "input2"),
                new ConfigFileDefinition("config3.conf", "input3"),
                new ConfigFileDefinition("config4.conf", "input4")
        );
        setupConfigFiles(tempDirectory, files);

        List<ConfigFileDefinition> otherFiles = Arrays.asList(
                new ConfigFileDefinition("config1.conf~", "input1"),
                new ConfigFileDefinition("config2.conf~", "input2"),
                new ConfigFileDefinition("config3.conf~", "input3"),
                new ConfigFileDefinition("config4.conf~", "input4")
        );
        setupConfigFiles(tempDirectory, otherFiles, files.size());

        Path readerConfig = tempDirectory;
        verifyConfig(readerConfig, files, tempDirectory);
    }

    @Test //when the path is a wildcard
    public void testConfigWithWildcardPath() throws IOException, ConfigLoadingException, IncompleteSourceWithMetadataException {
        final Path tempDirectory = Files.createTempDirectory("studtmp-");

        List<ConfigFileDefinition> files = Arrays.asList(
                new ConfigFileDefinition("config1.conf", "input1"),
                new ConfigFileDefinition("config2.conf", "input2"),
                new ConfigFileDefinition("config3.conf", "input3"),
                new ConfigFileDefinition("config4.conf", "input4")
        );
        setupConfigFiles(tempDirectory, files);

        List<ConfigFileDefinition> otherFiles = Arrays.asList(
                new ConfigFileDefinition("bad1.conf", "input1"),
                new ConfigFileDefinition("bad2.conf", "input2"),
                new ConfigFileDefinition("bad3.conf", "input3"),
                new ConfigFileDefinition("bad4.conf", "input4")
        );
        setupConfigFiles(tempDirectory, otherFiles, files.size());

        Path readerConfig = tempDirectory.resolve("conf*.conf");
        verifyConfig(readerConfig, files, tempDirectory);
    }

    @Test //URI defined path (file://..)
    public void testConfigWithURLdefinedPath() throws IOException, ConfigLoadingException, IncompleteSourceWithMetadataException {
        final Path tempDirectory = Files.createTempDirectory("studtmp-");

        List<ConfigFileDefinition> files = Collections.singletonList(
                new ConfigFileDefinition("config1.conf", "input1")
        );
        setupConfigFiles(tempDirectory, files);

        String readerConfig = "file://"+ tempDirectory.resolve("config1.conf").toString();
        verifyConfig(readerConfig, files, tempDirectory);
    }

    @Test //relative path
    public void testConfigWithRelativePath() throws IOException, ConfigLoadingException, IncompleteSourceWithMetadataException {
        final Path tempDirectory = Files.createTempDirectory("studtmp-");
        Files.createDirectory(tempDirectory.resolve("inside"));

        List<ConfigFileDefinition> files = Arrays.asList(
                new ConfigFileDefinition("config2.conf", "input1"),
                new ConfigFileDefinition("config1.conf", "input2")
        );
        setupConfigFiles(tempDirectory, files);
        Path readerConfig = tempDirectory.resolve("inside").resolve("../");
        verifyConfig(readerConfig, files, tempDirectory);
    }
}
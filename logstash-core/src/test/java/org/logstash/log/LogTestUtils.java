package org.logstash.log;

import org.apache.logging.log4j.core.LoggerContext;

import java.io.IOException;
import java.nio.file.FileSystems;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import static org.junit.Assert.assertTrue;

class LogTestUtils {

    static String loadLogFileContent(String logfileName) throws IOException {
        Path path = FileSystems.getDefault()
                .getPath(System.getProperty("user.dir"), System.getProperty("ls.logs"), logfileName);

        assertTrue("Log [" + path.toString() + "] file MUST exists", Files.exists(path));
        try (Stream<String> lines = Files.lines(path)) {
            return lines.collect(Collectors.joining());
        }
    }

    static void reloadLogConfiguration() {
        LoggerContext context = LoggerContext.getContext(false);
        context.stop(1, TimeUnit.SECONDS); // this forces the Log4j config to be discarded
    }

    static void deleteLogFile(String logfileName) throws IOException {
        Path path = FileSystems.getDefault()
                .getPath(System.getProperty("user.dir"), System.getProperty("ls.logs"), logfileName);
        Files.deleteIfExists(path);
    }
}

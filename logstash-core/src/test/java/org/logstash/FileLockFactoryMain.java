package org.logstash;

import java.io.IOException;
import java.nio.file.Paths;

/*
 * This program is used to test the FileLockFactory in cross-process/JVM.
 */
public class FileLockFactoryMain {

    public static void main(String[] args) {
        try {
            FileLockFactory.obtainLock(Paths.get(args[0]), args[1]);
            System.out.println("File locked");
            // Sleep enough time until this process is killed.
            Thread.sleep(Long.MAX_VALUE);
        } catch (InterruptedException e) {
            // This process is killed. Do nothing.
        } catch (IOException e) {
            // Failed to obtain the lock.
            System.exit(1);
        }
    }
}

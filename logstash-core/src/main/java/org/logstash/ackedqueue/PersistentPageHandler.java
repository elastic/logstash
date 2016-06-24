package org.logstash.ackedqueue;


import java.io.FileNotFoundException;
import java.nio.file.FileSystems;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;

public class PersistentPageHandler extends PageHandler {
    private String dirPath;

    // @param dirPath directory path where all queue data files will be written
    // @param pageSize the pageSize when creating a new queue, if the queue already exists, its configured page size will be used
    public PersistentPageHandler(String dirPath, int pageSize) throws FileNotFoundException {
        super(pageSize);
        this.dirPath = dirPath;

        Path p = FileSystems.getDefault().getPath(this.dirPath);

        if (Files.notExists(p, LinkOption.NOFOLLOW_LINKS)) {
            throw new FileNotFoundException(this.dirPath);
        }
    }

    // page is basically the byte buffer
    // @param index the page index to retrieve
    protected Page page(long index) {
        return null;
    }
}

package org.logstash.ackedqueue.io;

import java.nio.file.Path;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;
import org.logstash.ackedqueue.SequencedList;
import org.logstash.ackedqueue.StringElement;

import java.util.ArrayList;
import java.util.List;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;

public class FileMmapIOTest {
    private Path folder;
    private MmapPageIOV2 writeIo;
    private MmapPageIOV2 readIo;
    private int pageNum;

    @Rule
    public TemporaryFolder temporaryFolder = new TemporaryFolder();

    @Before
    public void setUp() throws Exception {
        pageNum = 0;
        folder = temporaryFolder
                .newFolder("pages")
                .toPath();
        writeIo = new MmapPageIOV2(pageNum, 1024, folder);
        readIo = new MmapPageIOV2(pageNum, 1024, folder);
    }

    @Test
    public void roundTrip() throws Exception {
        List<StringElement> list = new ArrayList<>();
        List<StringElement> readList = new ArrayList<>();
        writeIo.create();
        for (int i = 1; i < 17; i++) {
            StringElement input = new StringElement("element-" + i);
            list.add(input);
            writeIo.write(input.serialize(), i);
        }
        writeIo.close();
        readIo.open(1, 16);
        SequencedList<byte[]> result = readIo.read(1, 16);
        for (byte[] bytes : result.getElements()) {
            StringElement element = StringElement.deserialize(bytes);
            readList.add(element);
        }
        assertThat(readList, is(equalTo(list)));
    }
}

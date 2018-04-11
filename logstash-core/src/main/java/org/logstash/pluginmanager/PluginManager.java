package org.logstash.pluginmanager;

import com.squareup.okhttp.OkHttpClient;
import com.squareup.okhttp.Request;
import com.squareup.okhttp.Response;
import org.w3c.dom.Document;
import org.w3c.dom.NodeList;
import org.xml.sax.SAXException;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpression;
import javax.xml.xpath.XPathExpressionException;
import javax.xml.xpath.XPathFactory;
import java.io.IOException;
import java.util.Collection;
import java.util.Comparator;
import java.util.PriorityQueue;
import java.util.SortedSet;
import java.util.TreeSet;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import java.util.function.Function;
import java.util.stream.Collectors;

public class PluginManager {
    final ConcurrentHashMap<String, PluginInfo> registry = new ConcurrentHashMap<>();
    final static OkHttpClient http = new OkHttpClient();
    final static String DEFAULT_REPOSITORY_URL = System.getenv("LS_DEFAULT_MAVEN_URL");
    final static String DEFAULT_REPOSITORY_ID = "maven-releases";

    PluginManager() {

    }

    ConcurrentMap<PluginLocation, PluginInfo> installLatest(Collection<String> pluginLocationStrings) {
        return installLocations(pluginLocationStrings.stream().map(this::parseStringToPluginLocation).collect(Collectors.toList()));
    }


    ConcurrentMap<PluginLocation, PluginInfo> installLocations(Collection<PluginLocation> pluginLocations) {
        return pluginLocations.parallelStream().collect(Collectors.toConcurrentMap(Function.identity(), l -> {
            try {
                return this.installLatest(l);
            } catch (SAXException | IOException | ParserConfigurationException e) {
                // TODO This isn't production quality
                e.printStackTrace();
                return null;
            }
        }));
    }

    private PluginInfo installLatest(PluginLocation pluginLocation) throws IOException, ParserConfigurationException, SAXException {
        Collection<PluginVersion> pluginVersions = getPluginVersions(pluginLocation);
        Collection<PluginInfo> pluginInfos = getPluginInfos(pluginVersions);
        return null;
    }

    private Collection<PluginInfo> getPluginInfos(Collection<PluginVersion> pluginVersions) {
        return pluginVersions.parallelStream().map(this::getPluginInfo).collect(Collectors.toList());
    }

    private PluginInfo getPluginInfo(PluginVersion pluginVersion) {

    }

    private SortedSet<PluginVersion> getPluginVersions(PluginLocation pluginLocation) {
        SortedSet<PluginVersion> versions = new TreeSet<>();
        try {
            String url = metadataXmlURL(pluginLocation);
            Request request = new Request.Builder().url(url).build();
            Response response = http.newCall(request).execute();

            DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
            DocumentBuilder db = dbf.newDocumentBuilder();
            Document doc = db.parse(response.body().byteStream());

            XPathFactory xPathFactory = XPathFactory.newInstance();
            XPath xpath = xPathFactory.newXPath();

            NodeList result = (NodeList) xpath.evaluate("//metadata/versioning/versions/version/text()", doc, XPathConstants.NODESET);
            for (int i = 0; i < result.getLength(); i++) {
                String versionString = result.item(i).getTextContent();
                versions.add(new PluginVersion(versionString));
            }
            return null;
        } catch (IOException | ParserConfigurationException | SAXException | XPathExpressionException e) {
            // TODO handle for real
            e.printStackTrace();
        }

        return versions;
    }

    private String metadataXmlURL(PluginLocation pluginLocation) {
        return String.format(
                "%s/repository/%s/%s/%s/maven-metadata.xml",
                pluginLocation.repositoryUrl,
                pluginLocation.repositoryId,
                pluginLocation.group.replace(".", "/"),
                pluginLocation.artifact);
    }

    private String versionPomURL(PluginLocation pluginLocation, PluginVersion pluginVersion) {
        return String.format(
                "%s/repository/%s/%s/%s/maven-metadata.xml",
                pluginLocation.repositoryUrl,
                pluginLocation.repositoryId,
                pluginLocation.group.replace(".", "/"),
                pluginLocation.artifact);
    }

    private PluginLocation parseStringToPluginLocation(String string) {
        String[] split = string.split(":");
        switch(split.length) {
            case 2:
                return new PluginLocation(DEFAULT_REPOSITORY_URL, DEFAULT_REPOSITORY_ID, split[0], split[1]);
            case 4:
                return new PluginLocation(split[0], split[1], split[2], split[3]);
            default:
                return null; // TODO: Probably should throw instead
        }
    }
}

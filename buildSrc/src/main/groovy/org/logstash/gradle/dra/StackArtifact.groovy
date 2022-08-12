package org.logstash.gradle.dra

import groovy.transform.CompileStatic

/**
 * An artifact to be deployed on the elastic download service.
 */
@CompileStatic
class StackArtifact {

    /** The dir of the artifact in the built project. */
    private final String dir

    /** The name of the artifact in the built project. */
    private final String name

    /** The type of the artifact (i.e: maven, docker, deb, rpm, tar...) */
    private final String type

    /** A classifier for the artifact, which appears after the version */
    private final String classifier

    /** The CPU architecture (i.e: amd64, 386, x86, x86-64...) */
    private final String architecture

    /** The operating systems this artifact can be used with (i.e: linux, windows, darwin, templeOS...) */
    private final List<String> operatingSystems

    /** The licenses under which this artifact is distributed (i.e: apache-2.0, elastic-1.0, elastic-2.0, sspl-1.0) */
    private final List<License> licenses

    /** The project this artifact is associated with, or null if it does not matter. */
    private final String project

    /** The local build name this artifact came from, or null if it is not part of a local build definition */
    private final String localBuildName

    /** The file extension of the artifact. */
    private final String extension

    /** Whether the OS should be included in the file name of the artifact or not. */
    private final boolean includeOSInFileName

    /** Additional properties for the artifact which may be necessary when publishing. */
    private final Map<String, String> attributes

    /**
     * Licenses under which Elastic artifacts can be distributed.
     */
    enum License {
        APACHE_2("apache-2.0", "The Apache Software License, Version 2.0"),
        SSPL_1("sspl-1.0", "Server Side Public License, v 1"),
        ELASTIC_1_0 ("elastic-1.0", "Elastic License"),
        ELASTIC_2_0 ("elastic-2.0", "Elastic License 2.0")

        /** the value to add in the DSL (when possible the SPDX short identifier) */
        private String id
        /** the value expected in the file to check (when possible the SPDX full name)  */
        private String name

        public String getName() {
            return name
        }

        License (String id, String name) {
            this.name = name
            this.id = id
        }

        public static License getLicenseById(String id) {
            for (License license : values()) {
                if (license.id.equalsIgnoreCase(id)) {
                    return license
                }
            }
            throw new IllegalArgumentException("${id} is not a license handled by the unified release process.")
        }
    }

    private StackArtifact(String dir,
                          String name,
                          String type,
                          String classifier,
                          String project,
                          String localBuildName,
                          String extension,
                          String architecture,
                          List<String> operatingSystems,
                          List<License> licenses,
                          boolean includeOSInFileName,
                          Map<String, String> attributes)
    {
        this.dir = dir
        this.name = name
        this.type = type
        this.classifier = classifier
        this.project = project
        this.localBuildName = localBuildName
        this.extension = extension
        this.architecture = architecture
        this.operatingSystems = operatingSystems
        this.licenses = licenses
        this.includeOSInFileName = includeOSInFileName
        this.attributes = attributes != null ? Collections.unmodifiableMap(attributes) : Collections.<String, String>emptyMap()

        if (operatingSystems?.size() > 1 && includeOSInFileName) {
            throw new IllegalArgumentException("Cannot include multiple operating systems in a file name. ${this.toString()}")
        }
    }

    public String getPath(String version) {
        return "${dir}/${getName(version)}"
    }

    /**
     * The artifact name is based on the following pattern
     * (where the name ,version and extension are mandatory):
     *
     *  <pre>
     *      ${name}-${version}-${classifier}-${os}-${architecture}.${extension}
     *  <pre>
     */
    public String getName(String version) {
        if (type.equals('gem')) {
            // gems do not allow dashes in versions, so for prerelease we must adjust to their standard
            version = version.replace("-", ".")
        }

        String suffix = ""
        if (classifier != null) {
            suffix += "-${classifier}"
        }
        if (operatingSystems != null && includeOSInFileName && operatingSystems.size() == 1) {
            suffix += "-${operatingSystems[0]}"
        }
        if (architecture != null) {
            suffix += "-${architecture}"
        }
        return "${name}-${version}${suffix}.${extension}"
    }

    public String getDir() {
        return dir
    }

    public String getName() {
        return name
    }

    public String getType() {
        return type
    }

    public String getClassifier() {
        return classifier
    }

    public String getProject() {
        return project
    }

    public String getLocalBuildName() {
        return localBuildName
    }

    public String getExtension() {
        return extension
    }

    public String getArchitecture() {
        return architecture
    }

    public List<String> getOperatingSystems() {
        return operatingSystems
    }

    public List<License> getLicenses() {
        return licenses
    }

    public Map<String,String> getAttributes() {
        return attributes
    }

    public boolean isOss() {
        return attributes.get('oss') != null ?  Boolean.valueOf(attributes.get('oss')) : false
    }

    /**
     * Is it an artifact that aims to be used only internally?
     */
    public boolean isInternal() {
        return attributes.get('internal') != null ? Boolean.valueOf(attributes.get('internal')) : false
    }

    /**
     * Is this artifact included in the package repository?
     */
    public boolean isIncludeInRepo() {
        return attributes.get('include_in_repo') != null ? Boolean.valueOf(attributes.get('include_in_repo')) : true
    }

    @Override
    public boolean equals(o) {
        if (this.is(o)) return true
        if (getClass() != o.class) return false

        StackArtifact that = (StackArtifact) o

        if (attributes != that.attributes) return false
        if (classifier != that.classifier) return false
        if (dir != that.dir) return false
        if (name != that.name) return false
        if (project != that.project) return false
        if (localBuildName != that.localBuildName) return false
        if (type != that.type) return false
        if (extension != that.extension) return false
        if (architecture != that.architecture) return false
        if (operatingSystems != that.operatingSystems) return false
        if (licenses != that.licenses) return false
        if (includeOSInFileName != that.includeOSInFileName) return false

        return true
    }

    @Override
    public int hashCode() {
        int result
        result = (dir != null ? dir.hashCode() : 0)
        result = 31 * result + (name != null ? name.hashCode() : 0)
        result = 31 * result + (type != null ? type.hashCode() : 0)
        result = 31 * result + (classifier != null ? classifier.hashCode() : 0)
        result = 31 * result + (project != null ? project.hashCode() : 0)
        result = 31 * result + (localBuildName != null ? localBuildName.hashCode() : 0)
        result = 31 * result + (attributes != null ? attributes.hashCode() : 0)
        result = 31 * result + (extension != null ? extension.hashCode() : 0)
        result = 31 * result + (architecture != null ? architecture.hashCode() : 0)
        result = 31 * result + (operatingSystems != null ? operatingSystems.hashCode() : 0)
        result = 31 * result + (licenses != null ? licenses.hashCode() : 0)
        result = 31 * result + (includeOSInFileName ? includeOSInFileName.hashCode() : 0)

        return result
    }

    public String toString() {
        return "[name: '${name}', " +
                "dir: '${dir}', " +
                "type: '${type}', " +
                "classifier: '${classifier}', " +
                "project: '${project}', " +
                "localBuildName: '${localBuildName}', " +
                "attributes: '${attributes}', " +
                "extension: '${extension}', " +
                "architecture: '${architecture}', " +
                "operatingSystems: '${operatingSystems}', " +
                "licenses: '${licenses}', " +
                "includeOSInFileName: '${includeOSInFileName}']"
    }

    public static class Builder {
        private String dir
        private String name
        private String type
        private String classifier
        private String project
        private String localBuildName
        private Map<String, String> attributes
        private String extension
        private String architecture
        private List<String> operatingSystems
        private List<License> licenses
        private boolean includeOSInFileName
        public Builder(String name) {
            this.name = name
        }
        public Builder dir(String dir){
            this.dir = dir
            return this
        }
        public Builder type(String type){
            this.type = type
            return this
        }
        public Builder classifier(String classifier){
            this.classifier = classifier
            return this
        }
        public Builder project(String project){
            this.project = project
            return this
        }
        public Builder localBuildName(String localBuildName){
            this.localBuildName = localBuildName
            return this
        }
        public Builder extension(String extension){
            this.extension = extension
            return this
        }
        public Builder attributes(Map<String, String> attributes){
            this.attributes = attributes
            return this
        }
        public Builder architecture(String architecture){
            this.architecture = architecture
            return this
        }
        public Builder operatingSystems(List<String> operatingSystems){
            this.operatingSystems = operatingSystems
            return this
        }
        public Builder licenses(List<License> licenses){
            this.licenses = licenses
            return this
        }
        public Builder includeOSInFileName(boolean includeOSInFileName){
            this.includeOSInFileName = includeOSInFileName
            return this
        }
        public StackArtifact build() {
            return new StackArtifact(
                    this.dir,
                    this.name,
                    this.type,
                    this.classifier,
                    this.project,
                    this.localBuildName,
                    this.extension,
                    this.architecture,
                    this.operatingSystems,
                    this.licenses,
                    this.includeOSInFileName,
                    this.attributes
            )
        }
    }
}


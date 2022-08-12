package org.logstash.gradle.dra

import groovy.transform.CompileStatic
import org.gradle.api.tasks.Input
/**
 * A wrapper around configuring artifacts for a project.
 *
 * The type of artifacts handled by this wrapper are the following:
 * <ul>
 *     <li>maven</li>
 *     <li>javadoc</li>
 *     <li>gem</li>
 *     <li>docker</li>
 *     <li>msi</li>
 *     <li>rpm</li>
 *     <li>deb</li>
 *     <li>zip</li>
 *     <li>tar</li>
 * </ul>
 *
 * There is a specific one named <strong>pkg</strong> which generates <strong>rpm, tar (darwin, linux), zip and deb</strong>
 * files.
 *
 * The name, version and extension are the three mandatory fields for all the artifacts.
 * The filename, to get access to the generated file, is built following this pattern: <br/>
 *  <em>
 *      ${name}-${version}-${classifier}-${os}-${architecture}.${extension}
 *  </em>
 *
 */
@CompileStatic
class StackArtifactHandler implements Iterable<StackArtifact> {

    private final Set<StackArtifact> artifacts = new LinkedHashSet<>()

    private final List<StackArtifact> mavenArtifacts = []

    private final List<StackArtifact> javadocArtifacts = []

    private final List<StackArtifact> gemArtifacts = []

    private final List<StackArtifact> dockerArtifacts = []

    private final List<StackArtifact> packageArtifacts = []

    private final List<StackArtifact> zipArtifacts = []

    private final List<StackArtifact> tarArtifacts = []

    private final List<StackArtifact> debArtifacts = []

    private final List<StackArtifact> rpmArtifacts = []

    private final List<StackArtifact> pluginArtifacts = []

    private final List<StackArtifact> patchArtifacts = []

    private final List<StackArtifact> csvDependencyReportArtifacts = []

    /** The project these artifacts are for */
    @Input
    String project

    /** The local build these artifacts are for */
    String localBuildName

    /** The directory within a project to find the built artifact, or null no extra dir */
    @Input
    String buildDir

    /** Whether the artifacts for the project are generic or architecture specific */
    @Input
    boolean generic = true

    /** Classifier to use as part of the filename for a tarball Docker image file **/
    final static String DOCKER_IMAGE_CLASSIFIER = 'docker-image'

    @Override
    public Iterator<StackArtifact> iterator() {
        return artifacts.iterator()
    }

    public Set<StackArtifact> getArtifacts() {
        return artifacts
    }

    /** Return the artifacts for elastic's maven service and maven central. */
    public Collection<StackArtifact> getMavenArtifacts() {
        return mavenArtifacts
    }

    /** Return the javadoc jars to unzip and publish to javadoc.elastic.co. */
    public Collection<StackArtifact> getJavadocArtifacts() {
        return javadocArtifacts
    }

    /** Return the artifacts for rubygems.org. */
    public Collection<StackArtifact> getGemArtifacts() {
        return gemArtifacts
    }

    /** Return the artifacts for docker.elastic.co. */
    public Collection<StackArtifact> getDockerArtifacts() {
        return dockerArtifacts
    }

    /** Return the artifacts for all package files. */
    public Collection<StackArtifact> getPackageArtifacts() {
        return packageArtifacts
    }

    /** Return the zip artifacts */
    public Collection<StackArtifact> getZipArtifacts() {
        return zipArtifacts
    }

    /** Return the tar artifacts */
    public Collection<StackArtifact> getTarArtifacts() {
        return tarArtifacts
    }

    /** Return the artifacts for plugins for this project. */
    public Collection<StackArtifact> getPluginArtifacts() {
        return pluginArtifacts
    }

    public Collection<StackArtifact> getPatchArtifacts() {
        return patchArtifacts
    }

    public Collection<StackArtifact> getCsvDependencyReportArtifacts() {
        return csvDependencyReportArtifacts
    }

    /** Return the docker images artifacts alongside all the docker artifacts. */
    public Collection<StackArtifact> getDockerImagesArtifacts() {
        return dockerArtifacts.findAll{
            it -> it.getClassifier().contains(DOCKER_IMAGE_CLASSIFIER) == true
        }
    }

    /**
     * A maven artifact:
     * <ul>
     *     <li>is by default a file with .jar extension</li>
     *     <li></li>
     * </ul>
     */
    public void maven(Map<String,?> props) {
        // required values
        String type = 'maven'
        String name = getName(props)
        String dir = getDir(props)
        String extension = getOrDefault(props, 'extension', 'jar')
        List<StackArtifact.License> licenses = getLicenses(props)

        String group = getOrNull(props, 'group')
        if (group == null) {
            throw new IllegalArgumentException("Missing property 'group' for ${type} artifact ${name}")
        }

        // check properties not allowed for this kind of artifact
        checkPropertyNotAllowed(props, type, 'architecture')
        checkPropertyNotAllowed(props, type, 'os')
        checkPropertyNotAllowed(props, type, 'os32bit')

        // optional property
        String classifier = getOrNull(props, 'classifier')

        boolean oss = props.get('oss') != null ? props.get('oss') : false
        boolean internal = props.get('internal') != null ? props.get('internal') : false
        Map<String, String> attrs = new HashMap<String, String>() {{
            put("group", group)
            put("oss", Boolean.toString(oss))
            put("internal", Boolean.toString(internal))
            put("artifact_id", name)
            put("artifactNoKpi", Boolean.toString(true))
        }}

        List<StackArtifact> maven = new ArrayList<>()
        final StackArtifact pom = new StackArtifact.Builder(name)
                .dir(dir)
                .type(type)
                .classifier(classifier)
                .project(project)
                .localBuildName(localBuildName)
                .extension('pom')
                .licenses(licenses)
                .attributes(attrs)
                .build()
        maven.add(pom)
        final StackArtifact mainArtifact = new StackArtifact.Builder(name)
                .dir(dir)
                .type(type)
                .classifier(classifier)
                .project(project)
                .localBuildName(localBuildName)
                .extension(extension)
                .licenses(licenses)
                .attributes(attrs)
                .build()
        maven.add(mainArtifact)

        if (extension == 'jar') {
            // Automatically add any maven javadoc artifacts to the list of javadoc to be deployed
            StackArtifact javadoc = new StackArtifact.Builder(name)
                    .dir(dir)
                    .type(type)
                    .classifier('javadoc')
                    .project(project)
                    .localBuildName(localBuildName)
                    .extension(extension)
                    .licenses(licenses)
                    .attributes(attrs)
                    .build()

            maven.add(javadoc)
            javadocArtifacts.add(javadoc)
            maven.add(new StackArtifact.Builder(name)
                    .dir(dir)
                    .type(type)
                    .classifier('sources')
                    .project(project)
                    .localBuildName(localBuildName)
                    .extension(extension)
                    .licenses(licenses)
                    .attributes(attrs)
                    .build())
        }
        mavenArtifacts.addAll(maven)
        artifacts.addAll(maven)
    }

    public void javadoc(Map<String,?> props) {
        // required values
        String type = 'javadoc'
        String name = getName(props)
        String dir = getDir(props)
        String extension = getOrDefault(props, 'extension', 'jar')

        String group = getOrNull(props, 'group')
        if (group == null) {
            throw new IllegalArgumentException("Missing property 'group' for ${type} artifact ${name}")
        }

        // check properties not allowed for this kind of artifact
        checkPropertyNotAllowed(props, type, 'architecture')
        checkPropertyNotAllowed(props, type, 'os')
        checkPropertyNotAllowed(props, type, 'os32bit')

        // optional values
        String classifier = getOrDefault(props, 'classifier', 'javadoc')
        // default to false so we do not accidentally publish sources for commercial stuff
        boolean oss = props.get('oss') != null ? props.get('oss') : false

        Map<String, String> attrs = new HashMap<String, String>() {{
            put("group", group)
            put("oss", Boolean.toString(oss))
            put("artifactNoKpi", Boolean.toString(true))
        }}

        StackArtifact javadocs = new StackArtifact.Builder(name)
                .dir(dir)
                .type(type)
                .classifier(classifier)
                .project(project)
                .localBuildName(localBuildName)
                .extension(extension)
                .attributes(attrs)
                .build()
        artifacts.add(javadocs)
        javadocArtifacts.add(javadocs)
    }

    public void gem(Map<String,?> props) {
        // required values
        String type = 'gem'
        String name = getName(props)
        String dir = getDir(props)
        String extension = getOrDefault(props, 'extension', 'gem')

        checkPropertyNotAllowed(props, type, 'os32bit')

        Map<String, String> attrs = new HashMap<String, String>() {{
            put("artifactNoKpi", Boolean.toString(true))
        }}

        // optional values
        String architecture = getOrNull(props, 'architecture')
        List<String> operatingSystems = getOperatingSystems(props)
        String classifier = getOrNull(props, 'classifier')

        StackArtifact gem = new StackArtifact.Builder(name)
                .dir(dir)
                .type(type)
                .classifier(classifier)
                .project(project)
                .localBuildName(localBuildName)
                .extension(extension)
                .attributes(attrs)
                .architecture(architecture)
                .operatingSystems(operatingSystems)
                .includeOSInFileName(true)
                .build()
        artifacts.add(gem)
        gemArtifacts.add(gem)
        packageArtifacts.add(gem)
    }

    /**
     *
     * A docker type artifact could represent the image or a the build context.
     * If there is no classifier defined, by default it's @link{#DOCKER_IMAGE_CLASSIFIER}
     */
    public void docker(Map<String,?> props) {
        // required values
        String type = 'docker'
        String name = getName(props)
        String dir = getDir(props)
        String extension = getOrDefault(props, 'extension', 'tar.gz')

        checkPropertyNotAllowed(props, type, 'os32bit')

        // optional values
        String projectName = getOrDefault(props, 'project', project)
        String classifier = getOrDefault(props, 'classifier', DOCKER_IMAGE_CLASSIFIER)
        String architecture = getOrNull(props, 'architecture')
        List<String> operatingSystems = getOperatingSystems(props)

        // Docker image URL attributes
        String org = props.get('org')
        String repo = props.get('repo')
        String url = "${repo}/${org}/${name}"

        boolean internal = props.get('internal') != null ? props.get('internal') : false
        Map<String, String> attrs = new HashMap<String, String>() {{
            put("org", org)
            put("repo", repo)
            put("url", url)
            put("internal", Boolean.toString(internal))
            put("artifactNoKpi", Boolean.toString(true))
        }}

        StackArtifact docker = new StackArtifact.Builder(name)
                .dir(dir)
                .type(type)
                .classifier(classifier)
                .project(projectName)
                .localBuildName(localBuildName)
                .extension(extension)
                .architecture(architecture)
                .operatingSystems(operatingSystems)
                .includeOSInFileName(true)
                .attributes(attrs)
                .build()
        artifacts.add(docker)
        dockerArtifacts.add(docker)
        // Add the tar.gz docker artifacts to the package artifacts list
        packageArtifacts.addAll(docker)
    }

    public void zip(Map<String,?> props) {
        // required values
        String type = 'zip'
        String name = getName(props)
        String dir = getDir(props)
        String extension = getOrDefault(props, 'extension', 'zip')
        String projectName = getOrDefault(props, 'project', project)

        // optional values
        String classifier = getOrNull(props, 'classifier')
        String architecture = getOrDefault(props, 'architecture', 'x86_64')
        List<String> operatingSystems = getOperatingSystems(props, ['windows'])

        List<StackArtifact> zip = []
        if (artifactIsGeneric(props)) {
            zip.add(new StackArtifact.Builder(name)
                    .dir(dir)
                    .type(type)
                    .classifier(classifier)
                    .project(projectName)
                    .localBuildName(localBuildName)
                    .operatingSystems(operatingSystems)
                    .extension(extension)
                    .build())
        } else {
            zip.add(new StackArtifact.Builder(name)
                    .dir(dir)
                    .type(type)
                    .classifier(classifier)
                    .project(projectName)
                    .localBuildName(localBuildName)
                    .extension(extension)
                    .architecture(architecture)
                    .operatingSystems(operatingSystems)
                    .includeOSInFileName(true)
                    .build())
            if (artifactIsFor32BitOS(props)) {
                zip.add(new StackArtifact.Builder(name)
                        .dir(dir)
                        .type(type)
                        .classifier(classifier)
                        .project(projectName)
                        .localBuildName(localBuildName)
                        .extension(extension)
                        .architecture('x86')
                        .operatingSystems(operatingSystems)
                        .includeOSInFileName(true)
                        .build())
            }
        }
        artifacts.addAll(zip)
        packageArtifacts.addAll(zip)
        zipArtifacts.addAll(zip)
    }

    public void tar(Map<String,?> props) {
        // required values
        String type = 'tar'
        String name = getName(props)
        String dir = getDir(props)
        String extension = getOrDefault(props, 'extension', 'tar.gz')

        // optional
        String projectName = getOrDefault(props, 'project', project)
        String classifier = getOrNull(props, 'classifier')
        String architecture = getOrDefault(props, 'architecture', 'x86_64')
        List<String> operatingSystems = getOperatingSystems(props)

        List<StackArtifact> tar = []
        if (artifactIsGeneric(props)) {
            tar.add(new StackArtifact.Builder(name)
                    .dir(dir)
                    .type(type)
                    .classifier(classifier)
                    .project(projectName)
                    .localBuildName(localBuildName)
                    .extension(extension)
                    .operatingSystems(operatingSystems)
                    .build())
        } else {
            if (artifactIsFor32BitOS(props)) {
                tar.add(new StackArtifact.Builder(name)
                        .dir(dir)
                        .type(type)
                        .classifier(classifier)
                        .project(projectName)
                        .localBuildName(localBuildName)
                        .extension(extension)
                        .architecture('x86')
                        .operatingSystems(operatingSystems)
                        .includeOSInFileName(true)
                        .build())
            }
            tar.add(new StackArtifact.Builder(name)
                    .dir(dir)
                    .type(type)
                    .classifier(classifier)
                    .project(projectName)
                    .localBuildName(localBuildName)
                    .extension(extension)
                    .architecture(architecture)
                    .operatingSystems(operatingSystems)
                    .includeOSInFileName(true)
                    .build())
        }
        artifacts.addAll(tar)
        packageArtifacts.addAll(tar)
        tarArtifacts.addAll(tar)
    }

    public void deb(Map<String,?> props) {
        // required values
        String type = 'deb'
        String name = getName(props)
        String dir = getDir(props)
        String extension = 'deb'

        // check properties not allowed for this kind of artifact
        checkPropertyNotAllowed(props, type, 'os')

        // optional
        String projectName = getOrDefault(props, 'project', project)
        String classifier = getOrNull(props, 'classifier')
        String architecture = getOrDefault(props, 'architecture', 'amd64')

        boolean oss = props.getOrDefault('oss', false)
        boolean include_in_repo = props.getOrDefault('include_in_repo', true)
        Map<String, String> attrs = new HashMap<String, String>() {{
            put("oss", Boolean.toString(oss))
            put("include_in_repo", Boolean.toString(include_in_repo))
        }}
        List<StackArtifact> deb = []
        if (artifactIsGeneric(props)) {
            deb.add(new StackArtifact.Builder(name)
                    .dir(dir)
                    .type(type)
                    .classifier(classifier)
                    .project(projectName)
                    .localBuildName(localBuildName)
                    .extension(extension)
                    .attributes(attrs)
                    .build())
        } else {
            if (artifactIsFor32BitOS(props)) {
                deb.add(new StackArtifact.Builder(name)
                        .dir(dir)
                        .type(type)
                        .classifier(classifier)
                        .project(projectName)
                        .localBuildName(localBuildName)
                        .extension(extension)
                        .architecture('i386')
                        .attributes(attrs)
                        .build())
            }
            deb.add(new StackArtifact.Builder(name)
                    .dir(dir)
                    .type(type)
                    .classifier(classifier)
                    .project(projectName)
                    .localBuildName(localBuildName)
                    .extension(extension)
                    .architecture(architecture)
                    .attributes(attrs)
                    .build())
        }
        artifacts.addAll(deb)
        packageArtifacts.addAll(deb)
        debArtifacts.addAll(deb)
    }

    public void rpm(Map<String,?> props) {
        // required values
        String type = 'rpm'
        String name = getName(props)
        String dir = getDir(props)
        String extension = 'rpm'

        // check properties not allowed for this kind of artifact
        checkPropertyNotAllowed(props, type, 'os')

        // optional
        String projectName = getOrDefault(props, 'project', project)
        String classifier = getOrNull(props, 'classifier')
        String architecture = getOrDefault(props, 'architecture', 'x86_64')

        boolean oss = props.getOrDefault('oss', false)
        boolean include_in_repo = props.getOrDefault('include_in_repo', true)
        Map<String, String> attrs = new HashMap<String, String>() {{
            put("oss", Boolean.toString(oss))
            put("include_in_repo", Boolean.toString(include_in_repo))
        }}

        List<StackArtifact> rpm = []
        if (artifactIsGeneric(props)) {
            rpm.add(new StackArtifact.Builder(name)
                    .dir(dir)
                    .type(type)
                    .classifier(classifier)
                    .project(projectName)
                    .localBuildName(localBuildName)
                    .extension(extension)
                    .attributes(attrs)
                    .build())
        } else {
            if (artifactIsFor32BitOS(props)) {
                rpm.add(new StackArtifact.Builder(name)
                        .dir(dir)
                        .type(type)
                        .classifier(classifier)
                        .project(projectName)
                        .localBuildName(localBuildName)
                        .extension(extension)
                        .architecture('i686')
                        .attributes(attrs)
                        .build())
            }
            rpm.add(new StackArtifact.Builder(name)
                    .dir(dir)
                    .type(type)
                    .classifier(classifier)
                    .project(projectName)
                    .localBuildName(localBuildName)
                    .extension(extension)
                    .architecture(architecture)
                    .attributes(attrs)
                    .build())
        }
        artifacts.addAll(rpm)
        packageArtifacts.addAll(rpm)
        rpmArtifacts.addAll(rpm)
    }

    public void msi(Map<String,?> props) {
        // required values
        String type = 'msi'
        String name = getName(props)
        String dir = getDir(props)
        String extension = 'msi'

        // optional
        String projectName = getOrDefault(props, 'project', project)
        String classifier = getOrNull(props, 'classifier')
        String architecture = getOrNull(props, 'architecture')

        // keep operatingSystems here because the project esodbc uses windows in the msi filename
        List<String> operatingSystems = getOperatingSystems(props)

        List<StackArtifact> msi = []
        if (artifactIsGeneric(props)) {
            msi.add(new StackArtifact.Builder(name)
                    .dir(dir)
                    .type(type)
                    .classifier(classifier)
                    .project(projectName)
                    .localBuildName(localBuildName)
                    .extension(extension)
                    .operatingSystems(operatingSystems)
                    .build())
        } else {
            msi.add(new StackArtifact.Builder(name)
                    .dir(dir)
                    .type(type)
                    .classifier(classifier)
                    .project(projectName)
                    .localBuildName(localBuildName)
                    .extension(extension)
                    .architecture(architecture)
                    .operatingSystems(operatingSystems)
                    .includeOSInFileName(true)
                    .build())
            if (artifactIsFor32BitOS(props)) {
                msi.add(new StackArtifact.Builder(name)
                        .dir(dir)
                        .type(type)
                        .classifier(classifier)
                        .project(projectName)
                        .localBuildName(localBuildName)
                        .extension(extension)
                        .architecture('x86')
                        .operatingSystems(operatingSystems)
                        .includeOSInFileName(true)
                        .build())
            }
        }
        artifacts.addAll(msi)
        packageArtifacts.addAll(msi)
    }

    public void cppComponent(Map<String,?> props) {
        // required values
        String type = 'cppComponent'
        String name = getName(props)
        String dir = getDir(props)
        String extension = getOrDefault(props, 'extension', 'zip')
        String buildHost = props.get('buildhost')
        if (buildHost == null) {
            throw new IllegalArgumentException("Must specify buildhost for C++ artifact")
        }
        Map<String, String> attrs = ['buildhost': buildHost]

        checkPropertyNotAllowed(props, type, 'os32bit')

        // optional
        String projectName = getOrDefault(props, 'project', project)
        String classifier = getOrNull(props, 'classifier')
        String architecture = getOrNull(props, 'architecture')
        String artifactNoKpi = getOrNull(props, 'artifactNoKpi')
        List<String> operatingSystems = getOperatingSystems(props)

        if (artifactNoKpi != null) {
            if (artifactNoKpi != 'true' && artifactNoKpi != 'false') {
                throw new IllegalArgumentException("Invalid 'artifactNoKpi' of '${artifactNoKpi}', it must be 'true' or 'false'.")
            }
            attrs.put('artifactNoKpi', artifactNoKpi)
        }

        StackArtifact cppComponent = new StackArtifact.Builder(name)
                .dir(dir)
                .type(type)
                .classifier(classifier)
                .project(projectName)
                .localBuildName(localBuildName)
                .extension(extension)
                .architecture(architecture)
                .operatingSystems(operatingSystems)
                .includeOSInFileName(true)
                .attributes(attrs)
                .build()
        artifacts.add(cppComponent)
        packageArtifacts.addAll(cppComponent)
    }

    public void plugin(Map<String,?> props) {
        // required values
        String type = 'plugin'
        String name = getName(props)
        String dir = getDir(props)
        String extension = getOrDefault(props, 'extension', 'zip')

        checkPropertyNotAllowed(props, type, 'os32bit')

        // optional
        String projectName = getOrDefault(props, 'project', project)
        String classifier = getOrNull(props, 'classifier')
        String architecture = getOrNull(props, 'architecture')
        List<String> operatingSystems = getOperatingSystems(props)

        StackArtifact plugin = new StackArtifact.Builder(name)
                .dir(dir)
                .type(type)
                .classifier(classifier)
                .project(projectName)
                .localBuildName(localBuildName)
                .extension(extension)
                .architecture(architecture)
                .operatingSystems(operatingSystems)
                .includeOSInFileName(true)
                .build()
        artifacts.add(plugin)
        pluginArtifacts.add(plugin)
    }

    /**
     * <em>pkg</em> is a specific type to generate zip, deb, rpm and tar (linux 64/32 bits, darwin 64)
     * artifacts by declaring only one line in the DSL:
     *
     * <pre>
     *    pkg dir: 'greeting-library/build/pkg', name: 'my-artifact'
     * </pre>
     */
    public void pkg(Map<String,?> props) {
        zip(props)
        deb(props)
        rpm(props)

        if (artifactIsGeneric(props)) {
            props.put('os', ['linux', 'darwin'])
            tar(props)
        } else {
            props.put('os', ['linux'])
            tar(props)

            // no os32bit archive for darwin for pkg
            props.put('os', ['darwin'])
            props.put('os32bit', false)
            tar(props)
        }
    }


    public void patch(Map<String,?> props) {
        if (patchArtifacts.size() > 0) {
            throw new IllegalArgumentException("Only one patch artifact per project is currently supported.")
        }
        // required values
        final String type = 'patch'
        String name = getName(props)
        String dir = getDir(props)

        Map<String, String> attrs = new HashMap<String, String>() {{
            put("artifactNoKpi", Boolean.toString(true))
        }}

        final StackArtifact patch = new StackArtifact.Builder(name)
                .type(type)
                .dir(dir)
                .extension('patch')
                .attributes(attrs)
                .localBuildName(localBuildName)
                .build()
        artifacts.add(patch)
        patchArtifacts.add(patch)
    }

    public void csvDependencyReport(final Map<String,?> props) {
        // required values
        final String type = 'csvDependencyReport'
        final String name = getName(props)
        final String dir = getDir(props)

        // default internal to true
        final boolean internal = props.get('internal') != null ? props.get('internal') : true
        final Map<String, String> attrs = new HashMap<String, String>() {{
            put('internal', Boolean.toString(internal))
            put('artifactNoKpi', Boolean.toString(true))
        }}

        final StackArtifact csvDependencyReport = new StackArtifact.Builder(name)
                .type(type)
                .dir(dir)
                .extension('csv')
                .attributes(attrs)
                .localBuildName(localBuildName)
                .build()
        artifacts.add(csvDependencyReport)
        csvDependencyReportArtifacts.add(csvDependencyReport)
    }

    private static List<String> getOperatingSystems(final Map<String,?> props) {
        if (props?.get('os')) {
            return (List)props.get('os')
        } else {
            return Collections.emptyList()
        }
    }

    private static List<String> getOperatingSystems(final Map<String,?> props, final List<String> defaultValue) {
        if (getOperatingSystems(props)) {
            return getOperatingSystems(props)
        } else {
            return defaultValue
        }
    }

    private static List<StackArtifact.License> getLicenses(final Map<String,?> props) {
        List<StackArtifact.License> licenses = new ArrayList<>()
        if (props?.get('licenses')) {
            ((List<String>) props.get('licenses')).each { String id ->
                licenses.add(StackArtifact.License.getLicenseById(id))
            }
        }
        return licenses
    }

    private static String getName(Map<String,?> props) {
        String name = props.get('name')
        if (name == null) {
            throw new IllegalArgumentException("Must specify name for artifact")
        }
        return name
    }

    private String getDir(Map<String,?> props) {
        String dir = props.get('dir')
        if (dir == null) {
            dir = buildDir
        } else if (buildDir != null) {
            dir = "${dir}/${buildDir}"
        }
        return dir
    }

    private static String getOrNull(Map<String,?> props, String key) {
        getOrDefault(props, key, null)
    }

    private static String getOrDefault(Map<String,?> props, String key, String defaultValue) {
        if (props.get(key) != null) {
            return props.get(key)
        } else {
            return defaultValue
        }
    }

    private static void checkPropertyNotAllowed(Map<String,?> props, String type, String key) {
        if (props.get(key) != null) {
            throw new IllegalArgumentException("${key} is not allowed for ${type} artifact.")
        }
    }

    private boolean artifactIsGeneric(final Map<String,?> props) {
        boolean g = props.get('generic') != null ? props.get('generic') : false
        return (generic || g)
    }

    private static boolean artifactIsFor32BitOS(final Map<String,?> props) {
        boolean os32bit = props.get('os32bit') != null ? props.get('os32bit') : false
        return os32bit
    }
}


package org.logstash.gradle.dra.configuration

import groovy.transform.CompileStatic
import org.gradle.api.Action
import org.gradle.api.Project
import org.gradle.api.model.ObjectFactory
import org.gradle.api.provider.ListProperty
import org.gradle.api.provider.Property
import org.gradle.api.tasks.Nested
import org.gradle.api.tasks.Optional

@CompileStatic
class StackConfigurationPluginExtension {

    /** A random suffix intended to help uniquely identify a given build */
    private static String buildIdRandomSuffix

    /** Comma separated list of what projects to generate tasks for, when unset use all projects. */
    private Property<String> projects

    /**
     * If true, read the DSL for all projects, overriding the 'projects' property, and cause build task generation to be
     * skipped. This is used to enable tasks that require all the projects to be present at runtime, like report
     * generation and generating the trigger manifest, but no build commands or build command restrictions should be processed.
     *
     * Defaults to false.
     */
    private Property<Boolean> readAllProjectsAndSkipBuildTaskGeneration

    /** What local build to run */
    private Property<String> localBuild

    /** What artifact set to process */
    private Property<String> artifactSet

    /** The default base git URL to checkout projects codebase */
    private Property<String> defaultGitBaseURL

    /**
     * The conceptual branch that the release is based on. This normally corresponds to the git branch for the projects,
     * but it is possible for projects to use different branching strategies.
     */
    private Property<String> releaseBranch

    /** Comma separated list of manifest URLs for merging into a build */
    private Property<String> externalManifests

    /**
     * Comma separated list of projects to exclude external artifacts manifest urls for and ignore commit pinning from
     * external manifests and command line commit hash properties. For use when creating a Build Candidate using
     * non-latest artifacts. Default to empty string "".
     */
    private Property <String> projectsThatShouldIgnoreCommitPinning

    /**
     * The GitHub organization to add tags to when releasing.
     */
    private Property<String> gitHubOrganization

    /**
     * The author of commits when adding git tags.
     */
    private Property<String> gitTagAuthor

    /**
     * The email of commits when adding git tags.
     */
    private Property<String> gitTagEmail

    /** A flag to indicate whether the release-manager itself is running in a container (false by default) */
    private Property<Boolean> runInContainer

    /** A flag to indicate whether git checkouts of projects are required or not (true by default). */
    private Property<Boolean> scmCheckoutsRequired

    /**
     * The path where the artifacts are managed by the release-manager,
     * by default relative to the Gradle Project path.
     */
    private Property<String> workspacePath

    /** The folder where manifest files are uploaded to, defaults to an empty string */
    private Property<String> manifestsPath

    /** The folder where manifest files are downloaded from, default to "manifests" */
    private Property<String> downloadManifestsPath

    /**
     * The name of the manifest file to generate locally and upload to the bucket.
     *
     * Note that the final filename in the bucket gets the version appended. For example, if this property is set to
     *  manifest-A.json, the related file uploaded to the bucket would be named manifest-A-8.0.0-SNAPSHOT.json
     *
     *  The default value is: manifest
     */
    private Property<String> manifestFileName

    /** DownloadManifestArtifacts task will check and avoid downloading artifact .zip if one is already on disk. False by default */
    private Property<Boolean> skipDownloadWhenArtifactZipExists

    /**
     * The folder where artifacts should be expected for both snapshot and staging builds. For use with ArtifactsSets
     * from docker. Default is "" (empty string).
     */
    private Property<String> expectedArtifactsPathOverride

//    /** The instance for handling the versionConfiguration {} block */
//    private VersionConfiguration versionConfiguration

    /** Gradle project */
    private Project project

//    private TriggerConfiguration trigger

    public String stackVersion
    public String versionQualifier
    public String qualifiedVersion
    public String buildId

    StackConfigurationPluginExtension(final Project project) {
        this.project = project
        projects = project.getObjects().property(String.class)
        readAllProjectsAndSkipBuildTaskGeneration = project.getObjects().property(Boolean.class)
        localBuild = project.getObjects().property(String.class)
        artifactSet = project.getObjects().property(String.class)
        defaultGitBaseURL = project.getObjects().property(String.class)
        releaseBranch = project.getObjects().property(String.class)
        externalManifests = project.getObjects().property(String.class)
        projectsThatShouldIgnoreCommitPinning = project.getObjects().property(String.class)
        gitHubOrganization = project.getObjects().property(String.class)
        gitTagAuthor = project.getObjects().property(String.class)
        gitTagEmail = project.getObjects().property(String.class)
        runInContainer = project.getObjects().property(Boolean.class)
        scmCheckoutsRequired = project.getObjects().property(Boolean.class)
        workspacePath = project.getObjects().property(String.class)
        manifestsPath = project.getObjects().property(String.class)
        downloadManifestsPath = project.getObjects().property(String.class)
        manifestFileName = project.getObjects().property(String.class)
        skipDownloadWhenArtifactZipExists = project.getObjects().property(Boolean.class)
        expectedArtifactsPathOverride = project.getObjects().property(String.class)

        ObjectFactory objectFactory = project.getObjects()
//        trigger = objectFactory.newInstance(TriggerConfiguration.class)
//
//        versionConfiguration = new VersionConfiguration(project.properties, getBuildIdOverride())
    }

    void setProjects(final String projects) {
        this.projects.set(projects)
    }

    void setReadAllProjectsAndSkipBuildTaskGeneration(final Boolean readAllProjectsAndSkipBuildTaskGeneration) {
        this.readAllProjectsAndSkipBuildTaskGeneration.set(readAllProjectsAndSkipBuildTaskGeneration)
    }

    Boolean getReadAllProjectsAndSkipBuildTaskGeneration() {
        return getValue(readAllProjectsAndSkipBuildTaskGeneration.getOrElse(false), 'readAllProjectsAndSkipBuildTaskGeneration')
    }

    String getLocalBuild() {
        return getValue(localBuild.getOrElse(''), 'localBuild')
    }

    void setLocalBuild(final String localBuild) {
        this.localBuild.set(localBuild)
    }

    String getArtifactSet() {
        return getValue(artifactSet.getOrElse(''), 'artifactSet')
    }

    void setArtifactSet(final String artifactSet) {
        this.artifactSet.set(artifactSet)
    }

    String getDefaultGitBaseURL() {
        return getValue(defaultGitBaseURL.getOrNull(), 'defaultGitBaseURL')
    }

    void setDefaultGitBaseURL(final String defaultGitBaseURL) {
        this.defaultGitBaseURL.set(defaultGitBaseURL)
    }

    String getReleaseBranch() {
        return getValue(releaseBranch.getOrNull(), 'releaseBranch')
    }

    void setReleaseBranch(final String releaseBranch) {
        this.releaseBranch.set(releaseBranch)
    }


    String getExternalManifests() {
        return getValue(externalManifests.getOrElse(''), 'externalManifests')
    }

    void setExternalManifests(final String externalManifests) {
        this.externalManifests.set(externalManifests)
    }

    String getProjectsThatShouldIgnoreCommitPinning() {
        return getValue(projectsThatShouldIgnoreCommitPinning.getOrElse(''), 'projectsThatShouldIgnoreCommitPinning')
    }

    void setProjectsThatShouldIgnoreCommitPinning(final String projectsThatShouldIgnoreCommitPinning) {
        this.projectsThatShouldIgnoreCommitPinning.set(projectsThatShouldIgnoreCommitPinning)
    }

    Boolean getRunInContainer() {
        return getValue(runInContainer.getOrElse(false), 'runInContainer')
    }

    void setRunInContainer(final Boolean runInContainer) {
        this.runInContainer.set(runInContainer)
    }

    Boolean getScmCheckoutsRequired() {
        return getValue(scmCheckoutsRequired.getOrElse(true), 'scmCheckoutsRequired')
    }

    void setScmCheckoutsRequired(final Boolean scmCheckoutsRequired) {
        this.scmCheckoutsRequired.set(scmCheckoutsRequired)
    }

    String getWorkspacePath() {
        return getValue(workspacePath.getOrNull(), 'workspacePath')
    }

    void setWorkspacePath(final String workspacePath) {
        this.workspacePath.set(workspacePath)
    }

    String gitHubOrganization() {
        return getValue(gitHubOrganization.get(), 'gitHubOrganization')
    }

    void setGitHubOrganization(final String gitHubOrganization) {
        this.gitHubOrganization.set(gitHubOrganization)
    }

    String getGitTagAuthor() {
        return getValue(gitTagAuthor.get(), 'gitTagAuthor')
    }

    void setGitTagAuthor(final String gitTagAuthor) {
        this.gitTagAuthor.set(gitTagAuthor)
    }

    String getGitTagEmail() {
        return getValue(gitTagEmail.get(), 'gitTagEmail')
    }

    void setGitTagEmail(final String gitTagEmail) {
        this.gitTagEmail.set(gitTagEmail)
    }

    String getManifestsPath() {
        return getValue(manifestsPath.getOrElse(''), 'manifestsPath')
    }

    void setManifestsPath(final String manifestsPath) {
        this.manifestsPath.set(manifestsPath)
    }

    String getDownloadManifestsPath() {
        return getValue(downloadManifestsPath.getOrElse('manifests'), 'downloadManifestsPath')
    }

    void setDownloadManifestsPath(final String downloadManifestsPath) {
        this.downloadManifestsPath.set(downloadManifestsPath)
    }

    String getManifestFileName() {
        return getValue(manifestFileName.getOrElse("manifest"), 'manifestFileName')
    }

    void setManifestFileName(final String manifestsPath) {
        this.manifestFileName.set(manifestFileName)
    }

    String getExpectedArtifactsPathOverride() {
        return getValue(expectedArtifactsPathOverride.getOrElse(''), 'expectedArtifactsPathOverride')
    }

    void setExpectedArtifactsPathOverride(final String expectedArtifactsPathOverride) {
        this.expectedArtifactsPathOverride.set(expectedArtifactsPathOverride)
    }

//    public void trigger(Action<? super TriggerConfiguration> action) {
//        action.execute(trigger)
//    }
//
//    @Nested
//    @Optional
//    public TriggerConfiguration getTrigger() {
//        trigger.setEnable(getValue(Boolean.valueOf(trigger.getEnable()), 'trigger.enable'))
//        return trigger
//    }
//
//    void versionConfiguration(Action<? super VersionConfiguration> action) {
//        action.execute(versionConfiguration)
//        stackVersion = versionConfiguration.getVersion()
//        versionQualifier = versionConfiguration.getQualifier()
//        qualifiedVersion = versionConfiguration.qualifiedVersion()
//        buildId = getBuildId(qualifiedVersion)
//    }

    Boolean getSkipDownloadWhenArtifactZipExists() {
        return getValue(skipDownloadWhenArtifactZipExists.getOrElse(false), 'skipDownloadWhenArtifactZipExists')
    }

    void setSkipDownloadWhenArtifactZipExists(final Boolean skip) {
        this.skipDownloadWhenArtifactZipExists.set(skip)
    }

    public static String getBuildIdOverride() {
        final String buildIdProperty = System.getProperty('buildId')
        if (buildIdProperty == '') {
            return null
        } else if (buildIdProperty != null) {
            println("The system property 'buildId' is set to ${buildIdProperty}")
            return buildIdProperty
        } else {
            return null
        }
    }

    /** Returns a random 8 character hex value, intending to uniquely identify this build. */
    public static String getBuildIdRandomSuffix() {
        String buildIdOverride = getBuildIdOverride()

//        // Use the override if it exists. This must be checked every time so that the test framework is able to change
//        // the build id.
//        if (buildIdOverride != null) {
//            // There is a build id override set, get the random suffix from the specified build id.
//            buildIdRandomSuffix = new VersionConfiguration.BuildIdParser(buildIdOverride).getRandomSuffix()
//            return buildIdRandomSuffix
//        }

        // Make sure subsequent calls to this method return the same value.
        if (buildIdRandomSuffix != null) {
            return buildIdRandomSuffix
        }

        // there is not a build override set, and we haven't come up with a value yet, so generate one
        final char[] hexChars = '0123456789abcdef'.toCharArray()
        final Random r = new Random()
        final StringBuffer sb = new StringBuffer()
        while(sb.length() < 8) {
            final char randomChar = hexChars[r.nextInt(hexChars.length)]
            sb.append(randomChar)
        }
        buildIdRandomSuffix = sb.toString()

        return buildIdRandomSuffix
    }

    /** Returns a unique identifier for this build, based on the version and build hash. */
    public static String getBuildId(final String qualifiedVersion) {
        return "${qualifiedVersion}-${getBuildIdRandomSuffix()}"
    }

    /**
     *  A property can be defined in a DSL and overridden via the command line, e.g.
     *
     *  <pre>
     *
     *     configuration {
     *
     *       // Default base URL to checkout git projects
     *       defaultGitBaseURL = 'git@github.com:elastic'
     *       ...
     *     }
     *
     *  </pre>
     *
     *  This value can be overridden through the command line:
     *
     *  <pre>./gradlew clean -Pconfiguration.defaultGitBaseURL=https://github.com/elastic </pre>
     *
     * @param valueFromDSL value for a propertyName defined in the DSL
     * @param propertyName value defined via the command line -Pconfiguration.<propertyName>
     * @return the final value
     */
    private String getValue(final String valueFromDSL, final String propertyName) {
        if (getConfigurationProperty(propertyName)) {
            return getConfigurationProperty(propertyName)
        } else {
            return valueFromDSL
        }
    }

    private Boolean getValue(final Boolean valueFromDSL, final String propertyName) {
        if (getConfigurationProperty(propertyName)) {
            return Boolean.valueOf(getConfigurationProperty(propertyName))
        } else {
            return valueFromDSL
        }
    }

    private String getConfigurationProperty(final String propertyName) {
        if (project.hasProperty("configuration.${propertyName}")) {
            return project.property("configuration.${propertyName}").toString()
        } else {
            return null
        }
    }
}

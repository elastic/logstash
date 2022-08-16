package org.logstash.gradle.dra

import groovy.transform.CompileStatic
import org.gradle.api.Project
import org.gradle.api.Task
import org.logstash.gradle.dra.artifactset.ArtifactSet
import org.logstash.gradle.dra.artifactset.ArtifactSetHandler
import org.logstash.gradle.dra.configuration.StackConfigurationPluginExtension
import org.logstash.gradle.dra.localbuild.LocalBuild
import org.logstash.gradle.dra.localbuild.LocalBuildHandler

import java.nio.file.Paths

@CompileStatic
class StackProject {

    public static final String DEPENDENCIES_REPORTS_CSV_LOCAL_PATH = "reports/dependencies-reports"

    String releaseName

    /** The qualifier to pass to builds, i.e. 'alpha1' */
    public static String versionQualifier

    /** artifacts of this project */
    private final StackArtifactHandler stackArtifactHandler = new StackArtifactHandler()

    private final LocalBuildHandler localBuildHandler = new LocalBuildHandler()

    private final ArtifactSetHandler artifactSetHandler = new ArtifactSetHandler()

    private Map<String, String> statusMessages = [:]

    /** The gradle project we are attached to */
    private final Project gradleProject

    public String projectName = "logstash"

    StackConfigurationPluginExtension stackConfiguration

    private String workspacePath

    /** Task names for the build steps for the project. This is used to get metadata from the gradle tasks. */
    public List<String> buildTaskNames = new ArrayList<String>()

    public StackProject(Project gradleProject) {
        versionQualifier = "test-TODO-change"
        workspacePath = gradleProject.rootDir
        this.gradleProject = gradleProject
        this.stackConfiguration = new StackConfigurationPluginExtension(gradleProject)
        // TODO just for test, should be read by env properties with the help of StackConfigPluginExtension
        this.stackConfiguration.localBuild = "local"
        gradleProject.afterEvaluate {
            setupSnapshotTasks()
        }
    }

    /** Create and configure tasks for this project to build a snapshot version. */
    protected void setupSnapshotTasks() {
        final SharedBuildTasks sharedBuildTasks = setupCommonTasks(
                "snapshot",
                /*snapshotVersion*/ "8.0.0"
        )
        final Task buildTask = sharedBuildTasks.buildTask
    }

    public void localBuild(String name, Closure closure) {
        // only configure artifacts if we're actually building this localBuild
        boolean configureArtifacts = true/*stackConfiguration.localBuild == name*/
        localBuildHandler.localBuild(name, stackArtifactHandler, configureArtifacts, closure)
    }

    public void artifactSet(final String name, final Closure closure) {
        // only configure artifacts if we're actually handling this artifactSet
        final boolean configureArtifacts = true/*stackConfiguration.artifactSet == name*/
        artifactSetHandler.artifactSet(name, stackArtifactHandler, configureArtifacts, closure)
    }

    /** Set the shell commands to build a release of the project. */
    public void setStatusMessages(Map<String, String> statusMessages) {
        this.statusMessages = statusMessages
    }

    private SharedBuildTasks setupCommonTasks(final String type, final String version) {
        // if this project has local build command specified, and they are enabled with -Pconfiguration.localBuild=name
        boolean localBuildCommandsDefinedAndSpecified = false

        // if this project has an artifact set defined and enabled with -Pconfiguration.artifactSet=name
        boolean artifactSetDefinedAndSpecified = false

        String artifactsDirectory

        if (type == 'snapshot') {
            artifactsDirectory = "build"/*snapshotArtifactsDir*/
        } else if (type == 'release') {
            artifactsDirectory = "build"/*releaseArtifactsDir*/
        } else {
            throw new IllegalArgumentException("Unhandled type '${type}'.")
        }

        Collection<LocalBuild> specifiedLocalBuilds = List.of()

        if (localBuildHandler.getLocalBuilds().size() > 0) {
            specifiedLocalBuilds = localBuildHandler.getLocalBuilds().values().findAll({LocalBuild localBuild ->
                localBuild.name == stackConfiguration.localBuild
            })

            // if a local build is set, but we didn't find one, it does not exist so throw an exception
            if (stackConfiguration.localBuild != '' && specifiedLocalBuilds.size() == 0) {
                throw new IllegalArgumentException("The local build '${stackConfiguration.localBuild}' does not appear to exist.")
            }

            if (specifiedLocalBuilds.isEmpty()) {
                localBuildCommandsDefinedAndSpecified = false
            } else {
                localBuildCommandsDefinedAndSpecified = specifiedLocalBuilds.every { LocalBuild localBuild ->
                    if (type == 'snapshot') {
                        localBuild.buildSnapshotCommands != null && localBuild.buildSnapshotCommands.size() > 0
                    } else if (type == 'release') {
                        localBuild.buildReleaseCommands != null && localBuild.buildReleaseCommands.size() > 0
                    }
                }
            }
        }

        Collection<ArtifactSet> specifiedArtifactSets = List.of()

        if (artifactSetHandler.getArtifactSets().size() > 0) {
            specifiedArtifactSets = artifactSetHandler.getArtifactSets().values().findAll({ final ArtifactSet artifactSet ->
                artifactSet.name == stackConfiguration.artifactSet
            })

            // if an artifact set is set, but we didn't find one, it does not exist so throw an exception
            if (stackConfiguration.artifactSet != '' && specifiedArtifactSets.size() == 0) {
                throw new IllegalArgumentException("The artifact set '${stackConfiguration.artifactSet}' does not appear to exist.")
            }

            artifactSetDefinedAndSpecified = specifiedArtifactSets.size() > 0
        }

        if (!localBuildCommandsDefinedAndSpecified && !artifactSetDefinedAndSpecified) {
            throw new IllegalArgumentException("local builds and artifacts are not configured for '${projectName}'. There is not any DSL that release-manager needs in order to do anything for this project.")
        }

        Task buildTask = null

        if (specifiedArtifactSets.size() > 0) {
            final List<Task> artifactSetTasks = new ArrayList<>()

            for (final ArtifactSet artifactSet in specifiedArtifactSets) {
                // an artifactSetTask doesn't do anything, it just needs to end up being the buildTask
                final Task artifactSetTask = gradleProject.tasks.create("artifactSet-${projectName}-${artifactSet.name}-${type}")
                artifactSetTasks.add(artifactSetTask)
            }

            // boilerplate to be in control of task ordering
            for (int i = artifactSetTasks.size() - 1; i > 0; i--) {
                artifactSetTasks.get(i).shouldRunAfter(artifactSetTasks.get(i - 1))
            }
            // set the single "buildTask" to the last task in our set of artifact set tasks
            buildTask = artifactSetTasks.get(artifactSetTasks.size() - 1)
        }

        if (localBuildCommandsDefinedAndSpecified && specifiedLocalBuilds.size() > 0) {
            List<LocalBuildTask> localBuildTasks = new ArrayList<>()

            for (LocalBuild build : specifiedLocalBuilds) {
                LocalBuildTask localBuildTask = createLocalBuildTask(type, build, version, artifactsDirectory)
                buildTaskNames.add(localBuildTask.name)
                localBuildTasks.add(localBuildTask)
            }

            // set task order
            for (int i = localBuildTasks.size() - 1; i > 0; i--) {
                localBuildTasks.get(i).shouldRunAfter(localBuildTasks.get(i - 1))
            }
            // set the single "buildTask" to the last task in our set of local build tasks
            buildTask = localBuildTasks.get(localBuildTasks.size() - 1)
        }

        // All build tasks must depend on all check tasks
        // TODO re-enable when checks task is included
//        buildTask.dependsOn(gradleProject.tasks.findByName('checks'))

//        Task checksumTask = createChecksumTask(type, artifactsDirectory, version, 'SHA-512')
//        // calculate checksums after signing, because signing can modify some artifacts, like .deb packages
//        dependOnNullableTasks(checksumTask, [buildTask])

        SharedBuildTasks buildTasks = new SharedBuildTasks()
//        buildTasks.checksumTask = checksumTask
        buildTasks.buildTask = buildTask
        return buildTasks
    }

    private class SharedBuildTasks {
        public Task checksumTask
        public Task buildTask
    }

    /**
     * Generate the shell commands to run before a build process in a vagrant VM or a local build.
     */
    public static List<Object> linuxAndMacPreBuildCommands(final String projectDirectory, final String projectName,
                                                           final String type, final String syncDirectory,
                                                           final String version, final String expectedExternalArtifactPath) {
        List<Object> commands = []
        commands.addAll(
                // set variables in strings that support interpolation

                // PROJECT_CHECKOUT is where the git repository has been checked out
                "PROJECT_CHECKOUT=\"${syncDirectory}/checkouts/${projectName}/\"",

                // PROJECT_DIR is the directory where the build will be performed, avoid surrounding with "" since ~
                // needs to be expanded by the shell at runtime
                "PROJECT_DIR=${projectDirectory}",

                // EXTERNAL_ARTIFACTS_PATH is where downloaded artifacts should have ended up if there were any
                "EXTERNAL_ARTIFACTS_PATH=\"${expectedExternalArtifactPath}\"",
                "export ARTIFACTS_DIR=\"${syncDirectory}/build/${type}-artifacts\"",
                "export DEPENDENCIES_REPORTS_DIR=\"${syncDirectory}/build/${DEPENDENCIES_REPORTS_CSV_LOCAL_PATH}/\"",
                "export DEPENDENCIES_REPORT=\"${projectName}-${version}.csv\"",

                // now use single-quote strings for shell scripting to avoid needing a lot of confusing \ escapes

                // make the directories we'll be using and make sure they're clean
                'mkdir -p "$DEPENDENCIES_REPORTS_DIR"',
                // avoid "" to ensure ~ is expanded correctly
                'rm -rf $PROJECT_DIR',
                'mkdir -p $PROJECT_DIR',

                // now that project dir must exist get it's real path
                'PROJECT_DIR_ABSOLUTE_PATH="$(cd $PROJECT_DIR ; pwd)"',

                // only copy the checkout directory if it exists, this enables performing "builds" without a checked out
                // repository
                'if test -d "$PROJECT_CHECKOUT"',
                'then',
                '  rsync --recursive --links "$PROJECT_CHECKOUT" "$PROJECT_DIR_ABSOLUTE_PATH"',
                'else',
                '  echo "The directory \"$PROJECT_CHECKOUT\" does not exist, skipping copying repository to the build directory."',
                'fi',


                // if there are artifacts that were downloaded from somewhere else (external artifacts), move them into
                // the project directory
                'cd "$PROJECT_DIR_ABSOLUTE_PATH"',
                'shopt -s dotglob',
                'if ls "$EXTERNAL_ARTIFACTS_PATH"/* >/dev/null 2>&1',
                'then',
                '  mv "$EXTERNAL_ARTIFACTS_PATH"/* "$PROJECT_DIR_ABSOLUTE_PATH"',
                'fi',
                'shopt -u dotglob',
        )
        return commands
    }

    /**
     * Generate the shell commands to run after a build process in a vagrant VM or a local build.
     */
    public static List<Object> linuxAndMacPostBuildCommands(final String artifactDestinationPath,
                                                            final Set<StackArtifact> artifacts, final String version,
                                                            final String buildHostname, final String type) {
        List<Object> commands = []
        commands.addAll([
                // unset bash debugging and verbose mode to avoid logging of all the post build commands
                'set +x',
                'set +v',

                // a 'realpath' helper function to find the absolute path of files for better debugging output
                'rm_realpath() {',
                '  DIRECTORY_NAME="$(dirname "$1")"',
                '  if test -d "$DIRECTORY_NAME"',
                '  then',
                '    echo "$(cd "$DIRECTORY_NAME"; pwd)/$(basename "$1")"',
                '  else',
                // if the directory given does not exist, we can't use 'cd' and 'pwd' to get the real path, just
                // return what we were given to give some idea of what this thing was supposed to be
                '    echo "The directory \"$DIRECTORY_NAME\" does not exist. Returning a path that does not exist." >&2',
                '    echo "$1"',
                '  fi',
                '}',


                "rm -rf '${artifactDestinationPath}'",
                "mkdir -p '${artifactDestinationPath}'",

                // ARTIFACTS_MISSING is a flag that indicates expected artifacts were not found
                'ARTIFACTS_MISSING="false"',
        ])

        for (StackArtifact artifact : artifacts) {
            final String artifactPath = artifact.getPath(version)
            String artifactBuildHost = artifact.getAttributes().get('buildhost')
            if (artifactBuildHost != null && artifactBuildHost != buildHostname) {
                continue
            }
            // TODO: a hack to remove when 6.8.x will stop being released
            if (artifact.type == 'gem' && type == 'snapshot') {
                // a horrible hack for gems, which do not have a snapshot. without this, we would fail to
                // find the gems (which were not built for a snapshot build) when copying build artifacts
                continue
            }

            if (artifact.type == 'docker' && artifact.classifier == StackArtifactHandler.DOCKER_IMAGE_CLASSIFIER ) {
                final String image = "${artifact.attributes.get('url')}:${version}"
                commands.addAll([
                        // With async builds, Docker image tarballs are retrieved from the artifact bucket.
                        // Do not run 'docker save' if the image tarball exists on disk.
                        "if [ ! -f ${artifactPath} ]; then",
                        "echo 'Expecting the image ${image} to be present in the docker daemon.'",
                        "docker images ${image}",
                        // Ensure 'docker save' will fail even when piped into gzip
                        "set -o pipefail",
                        "mkdir -p \$(dirname '${artifactPath}')",
                        "docker save ${image} | gzip -c > '${artifactPath}'",
                        "else",
                        "echo '${artifactPath} already exists on disk, no need to execute docker save'.",
                        "fi"
                ])
            }

            final String fileDestination = "${artifactDestinationPath}/${artifactPath}"
            commands.addAll([
                    // set variables in strings that support interpolation
                    "ARTIFACT_PATH=\"${artifactPath}\"",
                    "FILE_DESTINATION=\"${fileDestination}\"",


                    // now use single-quote strings for shell scripting to avoid needing a lot of confusing \ escapes

                    'FULL_ARTIFACT_LOCATION="$(rm_realpath "$ARTIFACT_PATH")"',

                    'mkdir -p "$(dirname "$FILE_DESTINATION")"',

                    // if the file exists, copy it to the the destination
                    'if test -f "$FULL_ARTIFACT_LOCATION"',
                    'then',
                    '  cp "$FULL_ARTIFACT_LOCATION" "$FILE_DESTINATION"',
                    'else',
                    '  echo "Expected but did not find: \'$FULL_ARTIFACT_LOCATION\'."',
                    '  ARTIFACTS_MISSING="true"',
                    'fi'
            ])
        }

        commands.addAll([
                // fail if there are missing artifacts
                'if [[ "$ARTIFACTS_MISSING" == "true" ]]',
                'then',
                '  echo "There is a mismatch between the artifacts on disk and the artifacts DSL in release-manager, aborting."',
                '  exit 1',
                'fi',
        ])

        return commands
    }

    private LocalBuildTask createLocalBuildTask(final String type, final LocalBuild build,
                                                final String version, final String artifactResultDirectory) {
        LocalBuildTask task = gradleProject.tasks.create(taskName('localBuild', "${type.capitalize()}-${build.name}"), LocalBuildTask.class)
        task.projectName = projectName
        task.localBuildName = build.name
        task.type = type
        List<Object> commands = []

        final String gradleBuildDirectory = gradleProject.buildDir.absolutePath
//        if (parentDir != null) {
//            task.projectBuildDirectory = Paths.get(gradleBuildDirectory, 'projects', parentDir, projectName).toFile()
//        } else {
//            task.projectBuildDirectory = Paths.get(gradleBuildDirectory, 'projects', projectName).toFile()
//        }
        task.projectBuildDirectory = Paths.get(gradleBuildDirectory).toFile()
        // there isn't a sync directory, it's just the gradle directory since things are happening on the local filesystem
        final String gradleRootDirectory = gradleProject.getRootDir().absolutePath

        final String expectedExternalArtifactPath = "${workspacePath}/build/external-artifacts/${projectName}"

        // pre-build commands
        commands.addAll(
                linuxAndMacPreBuildCommands(task.projectBuildDirectory.absolutePath, projectName, type, gradleRootDirectory, version, expectedExternalArtifactPath)
        )

        // add dsl commands
        if (type == 'snapshot') {
            task.dslCommands = build.buildSnapshotCommands
            commands.addAll(build.buildSnapshotCommands)
        } else if (type == 'release') {
            task.dslCommands = build.buildReleaseCommands
            commands.addAll(build.buildReleaseCommands)
        } else {
            throw new IllegalArgumentException("Unhandled type '${type}' for local build task.")
        }

        // find the artifacts that are for this local build
        Set<StackArtifact> localBuildArtifacts = stackArtifactHandler.getArtifacts().findAll { StackArtifact artifact ->
            artifact.localBuildName == build.name
        }

        // post-build commands
        commands.addAll(
                linuxAndMacPostBuildCommands("${gradleRootDirectory}/${artifactResultDirectory}", localBuildArtifacts, version, '', type)
        )

        task.commands = commands

        return task
    }

    /** Returns a task name specific for this project */
    private String taskName(String action, String suffix) {
        return "${action}${projectName.replace('-', '').capitalize()}${suffix.capitalize()}"
    }
}

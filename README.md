## ![Duke, the Java mascot, waving](images/icon.png) Hello JavaFX!

This project is my template for building and packaging JavaFX applications. It uses Maven conventions for its directory structure and includes a sample application that prints "Hello World!" to standard output when its button is pressed.

The files in this project let you:

* open it in an Integrated Development Environment (IDE),
* build an executable Java archive (JAR),
* run and test the application, and
* package its API documentation and source files.

In addition to these standard artifacts, you can build packages for Linux that include a minimal Java runtime image. The table below shows the OpenJDK version, package file size, and package installed size for each type of package:

| Package Type       | OpenJDK | File (MB) | Installed (MB) |
| ------------------ |:-------:| ---------:| --------------:|
| Compressed archive | 15 |  29 |  87 |
| Debian package     | 15 |  20 |  89 |
| Snap package       | 11 | 136 | 136 |

The Snap file is mounted as a compressed read-only file system rather than extracted, so its size remains the same after installation.

### Building

The project includes support for the following build tools:

* [Apache Maven](https://maven.apache.org) - runs *online* with the Central Repository or *offline* with a local Debian repo
* [GNU Make](https://www.gnu.org/software/make/) - requires only the tools provided by OpenJDK
* [Snapcraft](https://snapcraft.io/build) - builds a self-contained application for any Linux distribution

The Maven `package` phase builds the following JAR files:

* target/hello-javafx-1.0.0.jar - JavaFX application
* target/hello-javafx-1.0.0-javadoc.jar - API documentation
* target/hello-javafx-1.0.0-sources.jar - Java source files

The Makefile `package` target builds the same JAR files into the `dist` directory. The `linux` target, along with the `install` target run by Snapcraft, builds the following Linux packages:

* dist/hello-javafx-1.0.0-linux-amd64.tar.gz - Compressed archive
* dist/hello-javafx_1.0.0-1_amd64.deb - Debian package
* hello-javafx_1.0.0_amd64.snap - Snap package

The Maven build can run on any system, but the Makefile is configured by default for Ubuntu. Whether you're running macOS, Windows, or Linux, you can use [Multipass](https://multipass.run) to build the project in an Ubuntu virtual machine (VM). For example, the following command will launch the Multipass [primary instance](https://multipass.run/docs/primary-instance) with 2 CPUs, 2 GiB of RAM, and Ubuntu 20.10 (Groovy Gorilla):

```console
$ multipass launch --name primary --cpus 2 --mem 2G groovy
```

All of the commands to build the software are run from the directory into which you cloned this repository, like this:

```console
$ git clone git@github.com:jgneff/hello-javafx.git
$ cd hello-javafx
$ mvn clean package
```

#### Apache Maven

The Maven [Project Object Model](pom.xml) lets you build this project using an IDE, such as Apache NetBeans, or directly from the command line with the command:

```console
$ mvn clean package
```

By default, the `mvn` command runs the build in *online* mode and downloads the required plugins and dependencies from the Maven Central Repository. On Debian-based systems such as Ubuntu, you can run the build in *offline* mode and use a local repository of plugins and dependencies built by your Linux distribution.

To run locally and offline, install Maven, the Maven Repo Helper, and the Maven plugins required for building the Javadoc and source archives:

```console
$ sudo apt install maven maven-debian-helper
$ sudo apt install libmaven-javadoc-plugin-java
$ sudo apt install libmaven-source-plugin-java
```

With those packages installed, you can build offline using only the local Debian repository as follows:

```console
$ mvn --settings /etc/maven/settings-debian.xml clean package
```

The Debian settings file for Maven contains just two items:

```XML
<!--
  This is a minimal settings.xml that switches maven to offline mode
  and uses the Debian repo as the local repo.
-->
<settings>
  <localRepository>/usr/share/maven-repo</localRepository>
  <offline>true</offline>
</settings>
```

Add the following Bash alias to have the `mvn` command always use the Debian settings:

```bash
# ~/.bash_aliases
alias mvn='mvn -s /etc/maven/settings-debian.xml'
```

#### GNU Make

The [Makefile](Makefile) builds the same JAR files as Maven, but it does so using only the tools that come with the Java Development Kit (JDK).

In addition, the Makefile can package the project as a self-contained application in the following formats:

* compressed archive for extracting to any location,
* Debian package for installing into `/opt` on Debian-based systems, and
* Snap package for testing locally and uploading to the [Snap Store](https://snapcraft.io/store).

Install the required packages with the command:

```console
$ sudo apt install openjdk-11-jdk-headless
$ sudo apt install junit4 binutils fakeroot
$ sudo snap install openjfx
```

Run the following command to build the JAR files into the `dist` directory:

```console
$ make clean package
```

Run the following command to build the compressed archive and Debian package for Linux:

```console
$ make linux
```

**Note:** The `jpackage` tool for building the Debian package is available in OpenJDK 14 or later, yet OpenJDK 14 contains a bug in the `jlink` tool that prevents it from building the custom runtime image (see "[jlink fails due to unexpected hash of java.* modules](https://bugs.launchpad.net/bugs/1868699)"). To work around the problem, install the [latest OpenJDK](https://jdk.java.net) and override the `JAVA_HOME` variable on the `make` command line:

```console
$ make clean package JAVA_HOME=$HOME/opt/jdk-15.0.1
```

You can also set the variable once for your entire session as follows:

```console
$ export JAVA_HOME=$HOME/opt/jdk-15.0.1
$ make clean package
```

#### Snapcraft

The [snapcraft.yaml](snap/snapcraft.yaml) file defines the build for Snapcraft. Run the following commands to install Snapcraft and build the Snap package:

```console
$ sudo snap install snapcraft
$ make clean
$ snapcraft
```

Snapcraft launches a new Multipass VM to ensure a clean and isolated build environment. The VM is named `snapcraft-hello-javafx` and runs the latest Ubuntu Long Term Support (LTS) release. The project's directory on the host system is mounted as `/root/project` in the guest VM, so any changes you make on the host are seen immediately in the guest, and vice versa.

**Note:** If you run the initial `snapcraft` command itself inside a VM, your system will need *nested VM* functionality. See the [Build Options](https://snapcraft.io/docs/build-options) page for alternatives.

If the build fails, you can run the command again with the `--debug` option to remain in the VM after the error:

```console
$ snapcraft -d
```

From within the VM, you can then clean the Snapcraft build and try again:

```console
# snapcraft clean app
Cleaning pull step (and all subsequent steps) for app
# snapcraft
```

The Snapcraft [*make* plugin](https://snapcraft.io/docs/make-plugin) uses the same [Makefile](Makefile) as before, but it runs GNU Make in the guest VM. The plugin runs `make` and `make install`, as shown below:

```console
# snapcraft
  ...
Pulling jni
'app' has dependencies that need to be staged: jni
Skipping pull jni (already ran)
Building jni
Staging jni
Pulling app
Skipping build jni (already ran)
Building app
+ make -j2
  ...
+ make -j2 install DESTDIR=/root/parts/app/install
  ...
Skipping stage jni (already ran)
Staging app
Priming jni
Priming app
Snapping
Snapped hello-javafx_1.0.0_amd64.snap
```

### Running

After building the executable JAR and installing the Linux packages, you can run the application in all of the following ways:

```console
$ java -p dist:/snap/openjfx/current/sdk/lib -m org.status6.hello
Hello World!
$ /opt/hello-javafx/bin/HelloJavaFX
Hello World!
$ ~/opt/hello-javafx/bin/HelloJavaFX
Hello World!
$ hello-javafx
NOTE: Picked up JDK_JAVA_OPTIONS: -Duser.home=/home/john/snap/hello-javafx/common
Hello World!
```

Those commands shows the application being launched:

* as the main class in a module,
* from the installed Debian package,
* from the *tar* archive extracted into `$HOME/opt`, and
* from the installed Snap package, which provides the command `hello-javafx`.

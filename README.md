## ![Duke, the Java mascot, waving](images/icon.png) Hello JavaFX!

This project is my template for building and packaging JavaFX applications. It follows the conventions of Apache Maven for its directory structure and includes a sample application that prints "Hello World!" to standard output when its button is pressed.

The files in this project let you:

* open it with an integrated development environment (IDE),
* build an executable Java archive (JAR),
* run and test the application, and
* package its documentation and source files.

In addition to these standard artifacts, you can build packages for Linux that include a minimal Java runtime image. The table below shows the file size and installed size of each package when built with OpenJDK 15. The Snap file is mounted as a compressed read-only file system, rather than extracted, so its installed size remains the same.

| Package Type | File (MB) | Installed (MB) |
| ------------ |:---------:|:--------------:|
| Compressed archive | 31 | 92 |
| Debian package     | 21 | 93 |
| Snap package       | 96 | 96 |

Furthermore, on Debian-based Linux distributions like Ubuntu, you can build all of these artifacts locally using only the trusted software from your system's package repositories.

### Building

This project includes support for the following build automation tools:

* [Apache Maven](https://maven.apache.org) - runs *online* with Maven Central or *offline* with a local Debian repo
* [GNU Make](https://www.gnu.org/software/make/) - requires only the tools provided by the Java Development Kit (JDK)
* [Snapcraft](https://snapcraft.io/build) - builds a self-contained application for any Linux distribution

The Maven `package` phase builds the following JAR files:

* Module org.status6.hello.javafx
    * target/hello-javafx-1.0.0.jar - JavaFX application
    * target/hello-javafx-1.0.0-javadoc.jar - API documentation
    * target/hello-javafx-1.0.0-sources.jar - Source code

The Makefile `package` target builds the same JAR files as Maven, but into the `dist` directory. The Makefile `linux` target, along with the `install` target run by Snapcraft, builds the following Linux packages:

* dist/hello-javafx-1.0.0-linux-amd64.tar.gz - Compressed archive
* dist/hello-javafx_1.0.0-1_amd64.deb - Debian package
* hello-javafx_1.0.0_amd64.snap - Snap package

The Maven build can run on any system, but the Makefile is configured by default for Ubuntu. Whether you're running Windows, macOS, or Linux, you can use [Multipass](https://multipass.run) to build the project in an Ubuntu virtual machine (VM). For example, the following command will launch the Multipass [primary instance](https://multipass.run/docs/primary-instance) with 2 CPUs, 4 GiB of RAM, and Ubuntu 20.04 LTS (Focal Fossa):

```console
$ multipass launch --name primary --cpus 2 --mem 4G focal
```

Run all of the commands to build the software from the directory into which you cloned this repository, as follows:

```console
$ git clone https://github.com/jgneff/hello-javafx.git
$ cd hello-javafx
$ mvn clean package
```

#### Apache Maven

The Maven [Project Object Model](pom.xml) lets you build the project using an IDE, such as Apache NetBeans, or directly from the command line with the command:

```console
$ mvn clean package
```

By default, the `mvn` command runs the build in *online* mode and downloads the required plugins and dependencies from the Maven Central Repository. On Debian-based systems such as Ubuntu, you can run the build in *offline* mode using a local repository of plugins and dependencies built by your Linux distribution.

To run the build locally, install Maven, the Maven Repo Helper, and the Maven plugins for building the Javadoc and source archives, as follows:

```console
$ sudo apt install maven maven-debian-helper
$ sudo apt install libmaven-javadoc-plugin-java
$ sudo apt install libmaven-source-plugin-java
```

Also install the required JavaFX libraries into the local Debian repo with the command:

```console
$ sudo apt install openjfx
```

With those packages installed, you can build offline using only the local Debian repository as shown below:

```console
$ mvn --settings /etc/maven/settings-debian.xml clean package
```

The Debian settings for Maven contain just two items:

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

Add the following Bash alias to make the `mvn` command always use the Debian settings:

```bash
# ~/.bash_aliases
alias mvn='mvn -s /etc/maven/settings-debian.xml'
```

#### GNU Make

The [Makefile](Makefile) builds the same JAR files as Maven, but it does so using only the tools and libraries that come with the Java Development Kit and the JavaFX Software Development Kit (SDK). You can install GNU Make and the latest release of OpenJDK and OpenJFX with the commands shown below. See the [OpenJDK Snap](https://github.com/jgneff/openjdk) and [OpenJFX Snap](https://github.com/jgneff/openjfx) repositories on GitHub for details.

```console
$ sudo apt install make
$ sudo snap install openjdk
$ sudo snap install openjfx
```

To run all of the Makefile targets, you'll also need the JUnit testing framework and two extra packages for building the Debian package:

```console
$ sudo apt install junit4 binutils fakeroot
```

Run `make` with the targets shown below to build the JAR files into the `dist` directory and run the unit test cases:

```console
$ . $(openjdk)
$ make clean package test
```

The `run` target runs the application from its executable JAR file:

```console
$ make run
```

With OpenJDK 14 or later, the Makefile can also package the project as a self-contained application in all of the following formats:

* compressed archive for extracting to any location,
* Debian package for installing into `/opt` on Debian-based systems, and
* Snap package for testing and uploading to the [Snap Store](https://snapcraft.io/store).

Run the following commands to build the compressed archive and Debian package for Linux:

```console
$ make linux
```

#### Snapcraft

The [snapcraft.yaml](snap/snapcraft.yaml) file defines the build for Snapcraft. Run the following commands to install Snapcraft and build the Snap package:

```console
$ sudo snap install snapcraft
$ make clean
$ snapcraft
```

Snapcraft launches a new Multipass VM to ensure a clean and isolated build environment. The VM is named `snapcraft-hello-javafx` and runs Ubuntu 20.04 LTS (Focal Fossa). The project's directory on the host system is mounted as `/root/project` in the guest VM, so any changes you make on the host are seen immediately in the guest, and vice versa.

**Note:** If you run the initial `snapcraft` command itself inside a VM, your system will need *nested VM* functionality. See the [Build Options](https://snapcraft.io/docs/build-options) page for alternatives, such as running a remote build or using an LXD container.

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
Building app
+ make -j4
  ...
+ make -j4 install DESTDIR=/root/parts/app/install
  ...
Snapping...
Snapped hello-javafx_1.0.0_amd64.snap
```

### Running

After building the executable JAR file and installing the Linux packages, you can run the application in all of the following ways:

* as the main class in a JAR file,
* as the main class in a module,
* from the compressed archive extracted into `~/opt`,
* from the installed Debian package, and
* from the installed Snap package.

Each of these methods is shown below:

```console
$ java -p /snap/openjfx/current/sdk/lib --add-modules javafx.controls \
    -jar dist/hello-javafx-1.0.0.jar
Hello World!
$ java -p dist/hello-javafx-1.0.0.jar:/snap/openjfx/current/sdk/lib \
    -m org.status6.hello.javafx
Hello World!
$ ~/opt/hello-javafx/bin/HelloJavaFX
Hello World!
$ /opt/hello-javafx/bin/HelloJavaFX
Hello World!
$ hello-javafx
Hello World!
```

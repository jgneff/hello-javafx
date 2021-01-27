# ======================================================================
# Makefile - builds the sample JavaFX application
# Copyright (C) 2020-2021 John Neffenger
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
# ======================================================================
# Build Requirements
#
# On Debian-based systems:
#   $ sudo apt install make default-jdk-headless
#   $ sudo apt install junit4 binutils fakeroot
#   $ sudo apt install openjfx
#
# On Fedora-based systems:
#   $ sudo dnf install make
#   $ sudo dnf install java-latest-openjdk-devel
#   $ sudo dnf install java-latest-openjdk-jmods
#   $ sudo dnf install junit binutils dpkg fakeroot
#   $ sudo dnf install openjfx
#
# Source the environment variables (modify as necessary):
#   bin/debian.env - for Debian-based systems (Makefile defaults)
#   bin/fedora.env - for Fedora-based systems
#
# Note: The Debian and Fedora 'openjfx' packages do not include the
# JMOD files for linking, so the resulting runtime image is missing the
# JavaFX native libraries (lib*.so) and the files 'javafx.properties'
# and 'javafx-swt.jar'. To build a complete runtime image, use the
# OpenJFX Snap package instead of the distribution packages:
#   $ sudo snap install openjfx
#
# The Snapcraft Make plugin runs this Makefile with:
#   $ make; make install DESTDIR=$SNAPCRAFT_PART_INSTALL
#
# Note: The 'jpackage' tool is available in JDK 14 or later.
# ======================================================================

# Java release for source code and target platform
rel = 11

# Project information
pkg = org.status6.hello
app = hello-javafx
ver = 1.0.0

# Package metadata
copyright   = "Copyright (C) 2020-2021 John Neffenger"
description = "Sample JavaFX application"
vendor      = "John Neffenger"
icon        = snap/gui/$(app).png
license     = LICENSE
email       = john@status6.com
group       = "Development;Building;"
revision    = 1
category    = java

# Launcher command names
cmd_javafx = HelloJavaFX

# Module names
mod_javafx = $(pkg).javafx

# JAR file names
jar_javafx = hello-javafx-$(ver).jar
jar_testfx = hello-testfx-$(ver).jar
src_javafx = hello-javafx-$(ver)-sources.jar
doc_javafx = hello-javafx-$(ver)-javadoc.jar

# Machine hardware name and Debian architecture
mach := $(shell uname --machine)
arch := $(shell dpkg --print-architecture)

# Package file names
package_tar = $(app)-$(ver)-linux-$(mach).tar.gz
package_deb = $(app)_$(ver)-$(revision)_$(arch).deb

# Overridden by variables from the environment
JAVA_HOME  ?= /usr/lib/jvm/default-java
JUNIT4     ?= /usr/share/java/junit4.jar
HAMCREST   ?= /usr/share/java/hamcrest-core.jar
JAVAFX_LIB ?= /usr/share/openjfx/lib
JAVAFX_MOD ?= /usr/share/openjfx/lib

# Overridden by variables on the Make command line
DESTDIR = dist/$(app)

# Commands
JAVA     = $(JAVA_HOME)/bin/java
JAVAC    = $(JAVA_HOME)/bin/javac
JAVADOC  = $(JAVA_HOME)/bin/javadoc
JAR      = $(JAVA_HOME)/bin/jar
JLINK    = $(JAVA_HOME)/bin/jlink
JPACKAGE = $(JAVA_HOME)/bin/jpackage

# Command options
JLINK_OPT = --strip-debug --no-header-files --no-man-pages \
    --add-modules $(mod_javafx) --launcher $(cmd_javafx)=$(mod_javafx)

JPACKAGE_OPT = --name $(cmd_javafx) --module $(mod_javafx) \
    --app-version $(ver) --copyright $(copyright) \
    --description $(description) --vendor $(vendor) \
    --icon $(icon) --license-file $(license)

# Debian package options
deb = --type deb --linux-package-name $(app) \
    --linux-deb-maintainer $(email) --linux-menu-group $(group) \
    --linux-app-release $(revision) --linux-app-category $(category)

# Defines a single space character
sp := $(subst ,, )

# Source and output directories
src = "./*/src/main/java"
out = build/classes
doc = build/apidocs
tst = build/testing

# Main JUnit class and test classes
junit = org.junit.runner.JUnitCore
tests = $(pkg).javafx.HelloTest

# Modular JAR libraries for compling and running, JMODs for linking
srcpath = --module-path $(JAVAFX_LIB) --module-source-path $(src)
runpath = --module-path $(JAVAFX_LIB) --add-modules javafx.controls
modpath = --module-path $(subst $(sp),:,$^ $(JAVAFX_MOD))

# Classpath additions for compiling and running tests
clspath = $(JUNIT4):$(HAMCREST):$(JAVAFX_LIB)/*

# Lists all non-module Java source files for testing
srctest = $(shell find $(pkg).*/src -name "*.java" \
            -a ! -name module-info.java)

# Lists prerequisites in pattern rules using secondary expansion
srcmain = $$(shell find $(pkg).%/src/main -name "*.java")

# Executable JAR options in pattern rules
execjar = --main-class $(pkg).$*.Hello --module-version $(ver)

# ======================================================================
# Pattern Rules
# ======================================================================

.SECONDEXPANSION:

dist/hello-%-$(ver).jar: $(srcmain) | dist
	$(JAVAC) --release $(rel) -d $(out) $(srcpath) --module $(pkg).$*
	$(JAR) --create --file $@ $(execjar) -C $(out)/$(pkg).$* .

dist/hello-%-$(ver)-javadoc.jar: $(srcmain) | dist
	$(JAVADOC) -quiet -d $(doc)/$(pkg).$* $(srcpath) --module $(pkg).$*
	$(JAR) --create --file $@ -C $(doc)/$(pkg).$* .

dist/hello-%-$(ver)-sources.jar: $(srcmain) | dist
	$(JAR) --create --file $@ -C $(pkg).$*/src/main/java .

dist/%.sha256: dist/%
	cd $(@D); sha256sum $(<F) > $(@F)

run-%: dist/hello-%-$(ver).jar
	$(JAVA) $(runpath) -jar $<

# ======================================================================
# Explicit Rules
# ======================================================================

.PHONY: all javadoc sources package install linux run test clean

all: dist/$(jar_javafx)

javadoc: dist/$(doc_javafx)

sources: dist/$(src_javafx)

package: all javadoc sources

install: $(DESTDIR)

linux: dist/$(package_tar).sha256 dist/$(package_deb).sha256

run: run-javafx

dist:
	mkdir -p $@

# The strip command works around the following issue, fixed in JDK 13:
# Create a jlink plugin for stripping debug info symbols from native libraries
# https://bugs.openjdk.java.net/browse/JDK-8214796
$(DESTDIR): dist/$(jar_javafx)
	rm -rf $(DESTDIR)
	$(JLINK) $(JLINK_OPT) $(modpath) --output $@
	strip --strip-debug $(DESTDIR)/lib/server/libjvm.so

dist/$(package_tar): $(DESTDIR)
	tar --create --file $@ --gzip -C $(<D) $(<F)

dist/$(package_deb): dist/$(jar_javafx)
	$(JPACKAGE) $(JPACKAGE_OPT) $(deb) $(modpath) --dest $(@D)

dist/$(jar_testfx): $(srctest) | dist
	$(JAVAC) --release $(rel) -d $(tst) --class-path $(clspath) $^
	$(JAR) --create --file $@ -C $(tst) .

test: dist/$(jar_testfx)
	$(JAVA) --class-path $<:$(clspath) $(junit) $(tests)

clean:
	rm -rf build dist

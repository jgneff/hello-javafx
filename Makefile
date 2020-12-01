# ======================================================================
# Makefile - builds the sample JavaFX application
# Copyright (C) 2020 John Neffenger
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
#
# This Makefile requires the following packages:
#   $ sudo apt install openjdk-11-jdk-headless
#   $ sudo apt install junit4 binutils fakeroot
#   $ sudo snap install openjfx
#
# The Snapcraft 'make' plugin runs this Makefile with:
#   $ make; make install DESTDIR=$SNAPCRAFT_PART_INSTALL
# ======================================================================

# OpenJDK version and target Java platform release
openjdk = 11
release = 11

# Prevents OutOfMemoryError running 'jlink' and 'jpackage'
maxheap = -XX:MaxHeapSize=1g

# Project information
project = hello-javafx
modname = org.status6.hello
appname = HelloJavaFX
version = 1.0.0

# Package metadata
description = "Sample JavaFX application"
copyright   = "Copyright (C) 2020 John Neffenger"
vendor      = "John Neffenger"
email       = john@status6.com
categories  = "Development;Building;"
section     = java
revision    = 1
icon        = snap/gui/hello-javafx.png
license     = LICENSE

# Debian architecture of build machine
arch := $(shell dpkg --print-architecture)

# Overridden by variables on the 'make' command line
JUNIT_JAR = /usr/share/java/junit4.jar
DESTDIR   = dist/$(project)

# Overridden by variables from the environment
JAVA_HOME  ?= /usr/lib/jvm/java-$(openjdk)-openjdk-$(arch)
JAVAFX_LIB ?= /snap/openjfx/current/sdk/lib
JAVAFX_MOD ?= /snap/openjfx/current/jmods

# Commands
JAVAC = $(JAVA_HOME)/bin/javac
JAR   = $(JAVA_HOME)/bin/jar
JAVA  = $(JAVA_HOME)/bin/java
JDOC  = $(JAVA_HOME)/bin/javadoc
JLINK = $(JAVA_HOME)/bin/jlink
JPKG  = $(JAVA_HOME)/bin/jpackage

# Command options
JAVAC_OPT = --release $(release)
JAR_OPT   = --create
JDOC_OPT  = -quiet --source-path src/main/java \
            --module-path $(JAVAFX_LIB)

JLINK_OPT = --strip-debug --no-header-files --no-man-pages \
            --add-modules $(modname) --launcher $(appname)=$(modname)

JPKG_OPT  = --module $(modname) --name $(appname) \
            --app-version $(version) --description $(description) \
            --copyright $(copyright) --vendor $(vendor) \
            --icon $(icon) --license-file $(license)

# Debian package options
debian = --type deb --linux-package-name $(project) \
    --linux-deb-maintainer $(email) --linux-menu-group $(categories) \
    --linux-app-category $(section) --linux-app-release $(revision)

# Java source files
sources := $(shell find src -name "*.java")

# Root source files for the Java compiler
root_info = src/main/java/module-info.java
root_main = src/main/java/org/status6/hello/HelloJavaFX.java
root_test = src/test/java/org/status6/hello/HelloJavaFXTest.java
list_main = $(root_info) $(root_main)
list_test = $(root_test) $(root_main)

# Main and test classes
main_class = org.status6.hello.HelloJavaFX
test_class = org.status6.hello.HelloJavaFXTest
main_junit = org.junit.runner.JUnitCore

# Application packages
package_deb = dist/$(project)_$(version)-$(revision)_$(arch).deb
package_tar = dist/$(project)-$(version)-linux-$(arch).tar.gz

# Other artifacts
modular_jar = dist/$(project)-$(version).jar
javadoc_jar = dist/$(project)-$(version)-javadoc.jar
sources_jar = dist/$(project)-$(version)-sources.jar
testing_jar = dist/$(project)-$(version)-testing.jar

# Options for the executable JAR file
executable = --main-class $(main_class) --module-version $(version)

# Module path and classpaths
mp_main = --module-path $(JAVAFX_LIB)
cp_unit = --class-path $(JUNIT_JAR):$(JAVAFX_LIB)/*
cp_test = --class-path $(testing_jar):$(JUNIT_JAR):$(JAVAFX_LIB)/*

# ======================================================================
# Pattern Rules
# ======================================================================

%.sha256: %
	cd $(@D); sha256sum $(<F) > $(@F)

# ======================================================================
# Explicit Rules
# ======================================================================

.PHONY: all package install linux run test clean

all: $(modular_jar)

package: $(modular_jar) $(javadoc_jar) $(sources_jar)

install: $(modular_jar) $(DESTDIR)

linux: $(package_deb).sha256 $(package_tar).sha256

dist:
	mkdir -p $@

$(modular_jar): $(sources) | dist
	$(JAVAC) $(JAVAC_OPT) -d build/classes $(mp_main) $(list_main)
	$(JAR) $(JAR_OPT) --file $@ $(executable) -C build/classes .

$(javadoc_jar): $(sources) | dist
	$(JDOC) $(JDOC_OPT) -d build/apidocs $(modname)
	$(JAR) $(JAR_OPT) --file $@ -C build/apidocs .

$(sources_jar): $(sources) | dist
	$(JAR) $(JAR_OPT) --file $@ -C src/main/java .

$(DESTDIR): export JAVA_TOOL_OPTIONS = $(maxheap)
$(DESTDIR): $(modular_jar)
	rm -rf $(DESTDIR)
	$(JLINK) $(JLINK_OPT) --module-path $<:$(JAVAFX_MOD) --output $@
	strip --strip-debug $(DESTDIR)/lib/server/libjvm.so

$(package_deb): export JAVA_TOOL_OPTIONS = $(maxheap)
$(package_deb): $(modular_jar)
	$(JPKG) $(JPKG_OPT) $(debian) --module-path $<:$(JAVAFX_MOD) --dest $(@D)

$(package_tar): $(DESTDIR)
	tar --create --file $@ --gzip -C $(<D) $(<F)

$(testing_jar): $(sources) | dist
	$(JAVAC) $(JAVAC_OPT) -d build/test-classes $(cp_unit) $(list_test)
	$(JAR) $(JAR_OPT) --file $@ -C build/test-classes .

run: $(modular_jar)
	$(JAVA) --module-path $<:$(JAVAFX_LIB) --module $(modname)

test: $(testing_jar)
	$(JAVA) $(cp_test) $(main_junit) $(test_class)

clean:
	rm -rf build dist

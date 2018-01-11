# linux-installer

Simple installer for embedded Linux systems.

## Introduction

__linux-installer__ prepares, partitions disks, creates filesystems, installs
a bootloader and copies file images into the system.

All instructions are given by configuration files. For examples see

    conf/installer.json
    conf/installer.log

## Installation

Best way is to use the cpanm tool.

    $ perl Makefile.pl
    $ make dist
    $ VERSION=$(perl -le 'require "./lib/Linux/Installer.pm"; print $Linux::Installer::VERSION')
    $ cpanm Linux-Installer-$VERSION.tar.gz

## Usage

Following command will create a BIOS/EFi bootable system and copy prepared
root files.

    $ linux-installer --config-file conf/installer.json --log-config-file conf/installer.log.conf /dev/sdb

### License

http://dev.perl.org/licenses/

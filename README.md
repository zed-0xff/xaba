xaba
======

Description
-----------
(un)packer for [Xamarin assemblies.blob](https://github.com/xamarin/xamarin-android/blob/main/Documentation/project-docs/AssemblyStores.md)

Installation
------------

    gem install xaba

Usage
-----

    # xaba -h

    Usage: xaba [options] [files]
    Commands:
        -l, --list                       List assemblies in the blob
        -u, --unpack                     Unpack all or specified file(s)
        -r, --replace                    Replace file(s) in the blob
    
    Options:
        -m, --manifest PATH              Pathname of the input assemblies.manifest file
        -b, --blob PATH                  [and/or] pathname of the input assemblies.blob file
    
        -o, --output PATH                Pathname for the output assemblies.blob file when replacing
                                         Pathname for the output dir when unpacking
        -v, --verbose                    Increase verbosity
            --version                    Prints the version
        -h, --help                       Prints this help

License
-------
MIT

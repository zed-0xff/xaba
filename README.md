xaba
======

Description
-----------
A pure ruby implementation of win32 PE binary files dumper.

Usage
-----

    # xaba -h

    Usage: xaba [options]
    Commands:
        -l, --list                       List assemblies in the blob
        -u, --unpack [FILE]              Unpack all files or a specified file
        -r, --replace FILE               Replace one file in the blob
    
    Options:
        -m, --manifest PATH              Pathname of the input assemblies.manifest file
        -b, --blob PATH                  [and/or] pathname of the input assemblies.blob file
    
        -o, --output PATH                Pathname for the output assemblies.blob file when replacing
                                         Pathname for the output dir when unpacking
        -v, --verbose                    Increase verbosity
        -h, --help                       Prints this help

License
-------
MIT

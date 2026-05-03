### Changelog

#### 1.0.0+2

* Byte-level path manipulation API (`PathBuf`)
* Cross-platform support for POSIX and Windows paths
* Automatic platform detection with optional manual override
* Full Windows prefix support:

    * Disk (`C:\`)
    * UNC (`\\server\share`)
    * Device namespace (`\\.\`)
    * Verbatim (`\\?\`)
    * Verbatim UNC and Verbatim Disk
* Correct handling of UTF-8 (POSIX) and UTF-16 (Windows)
* Safe handling of non-UTF-8 and malformed sequences
* Component-based path parsing and iteration
* Support for emoji and foreign language paths

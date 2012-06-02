About DTFoundation
==================

DTFoundation is a collection of utility methods and category extensions that *Cocoanetics* is standardizing on. This should evolve into a toolset of well-documented and -tested code to accelerate future development.
 
At a Glance
-----------
Contained are several category methods

- NSString+DTFormatNumbers - formatting Numbers
- NSString+DTPaths - working with paths
- NSURL+DTPrefLinks - getting direct-access URLs for preferences
- NSURL+DTAppLinks - getting direct-access URLs for an app's app store and review page
- UIImage+DTFoundation - helpful methods for drawing images
- UIView+DTFoundation - helpful methods for working with views

Other classes simplify working with specialized data

- DTASN1Parser - a parser for ASN.1-encoded data (eg. Certificates)
- DTAsyncFileDeleter - asynchronous non-blocking file/folder deletion
- DTDownload - asynchronous file download with optional resume
- DTHTMLParser - a libxml2-based HTML parser
- DTVersion - parsing and comparing version numbers
- DTZipArchive - uncompressing ZIP and GZ files

License
------- 
 
It is open source and covered by a standard BSD license. That means you have to mention *Cocoanetics* as the original author of this code. You can purchase a Non-Attribution-License from us.

Documentation
-------------

Documentation can be [browsed online](http://cocoanetics.github.com/DTFoundation) or installed in your Xcode Organizer via the [Atom Feed URL](http://cocoanetics.github.com/DTFoundation/DTFoundation.atom).

Usage
-----

The DTFoundation.framework is using the "Fake Framework" template put together by [Karl Stenerud](https://github.com/kstenerud/iOS-Universal-Framework). All categories employ Karl's LoadabeCategory hack to avoid having to use the -all_load linker flag. If your app does not use ARC yet (but DTFoundation does) then you also need the -fobjc-arc linker flag.

1. Include the DTFoundation.framework in your project. 
2. Import the DTFoundation.h in your PCH file or include the individual header files where needed.
3. Add -ObjC to "Other Linker Flags".
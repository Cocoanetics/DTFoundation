About DTFoundation
==================

DTFoundation is a collection of utility methods and category extensions that *Cocoanetics* is standardizing on. This should evolve into a toolset of well-documented and -tested code to accelerate future development.
 
At a Glance
-----------
Contained are several category methods

- NSArray+DTError - parsing array property lists with error reporting
- NSData+Base64 - Matt Gallagher's base64 methods
- NSData+DTCrypto - Cryptography methods for NSData
- NSDictionary+DTError - parsing dictionary property lists with error reporting
- NSMutableArray+DTMoving - moving multiple array elements to a new location
- NSObject+DTRuntime - runtime hacking methods
- NSString+DTFormatNumbers - formatting Numbers
- NSString+DTUtilities - various utility methods for strings
- NSString+DTPaths - working with paths
- NSString+DTURLEncoding - URL encoding methods
- NSString+DTUTI - string utility methods using UTIs
- NSURL+DTUnshorten - unshorting of NSURLs
- NSURL+DTAppLinks - getting direct-access URLs for an app's app store and review page
- UIImage+DTFoundation - helpful methods for drawing images
- UIView+DTFoundation - helpful methods for working with views

Other classes simplify working with specialized data

- DTActionSheet - block-based additions for UIActionSheet
- DTASN1Parser - a parser for ASN.1-encoded data (eg. Certificates)
- DTAsyncFileDeleter - asynchronous non-blocking file/folder deletion
- DTCustomColoredAccessory - a customizable accessory view for UITableView
- DTExtendedFileAttributes - access and modify extended file attributes
- DTHTMLParser - a libxml2-based HTML parser
- DTPieProgressIndicator - pie-shaped progress indicator
- DTScripting - things to work with Objective-C script
- DTSmartPagingScrollView - a page-based scroll view
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

About DTFoundation
==================

DTFoundation is a collection of utility methods and category extensions that *Cocoanetics* is standardizing on. This should evolve into a toolset of well-documented and -tested code to accelerate future development.

Methods, categories and functions are grouped into Subspecs. The grouping determined by the required dependencies. Please refer the programming guides linked from the documentation site for their contents.

- **Core:** Enhancements for Apple frameworks and classes which are usable on Mac and iOS.
- **UIKit**
- **UIKit Blocks Additions**
- **AppKit**
- **DTAWS**
- **DTASN1**
- **DTHTMLParser**
- **DTReachability**
- **DTSidePanel**
- **DTSQLite**
- **DTUTI**
- **DTZipArchive**

License
-------

It is open source and covered by a standard 2-clause BSD license. That means you have to mention *Cocoanetics* as the original author of this code and reproduce the LICENSE text inside your app. 

You can purchase a [Non-Attribution-License](http://www.cocoanetics.com/order/?product=DTFoundation%20Non-Attribution%20License) for 75 Euros for not having to include the LICENSE text.

We also accept sponsorship for specific enhancements which you might need. Please [contact us via email](mailto:oliver@cocoanetics.com?subject=DTFoundation) for inquiries.

Documentation
-------------

Documentation can be [browsed online](https://docs.cocoanetics.com/DTFoundation) or installed in your Xcode Organizer via the [Atom Feed URL](https://docs.cocoanetics.com/DTFoundation/DTFoundation.atom).

Usage
-----

The DTFoundation.framework is using the "Fake Framework" template put together by [Karl Stenerud](https://github.com/kstenerud/iOS-Universal-Framework). If your app does not use ARC yet (but DTFoundation does) then you also need the -fobjc-arc linker flag.

1. Include the DTFoundation.framework in your project. 
2. Import the DTFoundation.h in your PCH file or include the individual header files where needed.
3. Add -ObjC to "Other Linker Flags".

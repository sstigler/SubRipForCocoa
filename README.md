SubRip
======

A parser for .srt files writing in Objective-C.

Usage
-----

Add “SubRip.xcodeproj” to your project (preferably into “Frameworks” to keep things tidy).

In your target’s “Build Phases”:

* Add Build Phase (+-button pull-down menu) > Copy Files
* Destination: Frameworks
* Change name to “Copy Frameworks” to keep things clean

Add “SubRip.framework” to the following build phases (via the +-buttons):

* “Target Dependencies”
* “Link Binary With Libraries”
* “Copy Frameworks” (created above)

And finally add the header to your code:

    #import <SubRip/SubRip.h>


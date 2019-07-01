# QNEAppProxy

QNEAppProxy shows how to implement a basic Network Extension app proxy tunnel provider.


## Requirements

### Build

Xcode 9.0

The sample was built using Xcode 9.0 on OS X 10.12.6 with the iOS 11.0 SDK.  To build the sample open the project, make sure the `App-iOS` scheme is selected, and choose *Product* > *Build*.

+++ discussion of provisioning

### Runtime

iOS 10.0

The core code should work on iOS 9 but the bulk of the testing was done on iOS 10 and later.


## Packing List

The sample contains the following items:

* `README.md` — This file.

* `LICENSE.txt` — The standard sample code license.

* `QNEAppProxy.xcodeproj` — An Xcode project for the sample.

* `+++ stuff` — +++ description of stuff


## Using the Sample

+++


## Caveats

The *TestApp-iOS* target exists because an app proxy provider can’t catch the network connections issued by its containing app.

When testing `SafariDomains` make sure to remove `NETestAppMapping` from the app’s `Info.plist` because that test setting interferes with the normal operation of `SafariDomains`.

The app requests to post user notification on launch because I used it to confirm that Network Extension providers can post such notifications via the User Notifications framework.


## Feedback

If you find any problems with this sample, or you’d like to suggest improvements, please [file a bug][bug] against it.

[bug]: <http://developer.apple.com/bugreporter/>


## Version History

1.0d1 (6 Jan 2017) was distributed to a small number of developers on a one-to-one basic.

1.0d2 (2 Feb 2017) was distributed to a small number of developers on a one-to-one basic.  Add a test app target that is enrolled in the per-app VPN.  Changed the network test infrastructure such that it can run inside the app proxy provider.

1.0d3 (2 Oct 2017) was distributed to a small number of developers on a one-to-one basis. Switched to using automatic code signing. Updated to Xcode 9. Moved all the test code to the test app. Added some caveats to the read me. Added a macOS build. Got on `OnDemandMatchAppEnabled` working on macOS.

1.0d4 (4 Oct 2017) was distributed to a small number of developers on a one-to-one basis. It fixed a problem with 1.0d3 where it was missing some expected features due to a tagging error.

Share and Enjoy

Apple Developer Technical Support  
Core OS/Hardware

4 Oct 2017

Copyright (C) 2017 Apple Inc. All rights reserved.

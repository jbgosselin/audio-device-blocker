Audio Device Blocker
====================

![AppIcon](/audio-device-blocker/Assets.xcassets/AppIcon.appiconset/AppIcon-256.png)

Why?
----

Are you tired of your mac automatically switching to the microphone of your bluetooth headset?

I was, so I decided to create a small tray App to ban my bluetooth headset microphone from connecting automatically.
Additionally, this works with any input or output audio device.

How does it work?
-----------------

It runs in the notification tray and monitors when:
- An audio device is plugged-in plugged-out
- The main output/input device changes

When a blocklisted device is plugged-in and the system automatically switch to it:
- Reverts back to the previously used device
- Fallbacks to a list of devices with a defined order of preference
- Notifies you when a device has been blocked

More informations
-----------------

- Runs on MacOS 11.0+ (Big Sur and ongoing)
- The provided release runs on both Intel & ARM based Mac
- I do not have a paid Apple Developer Membership so be ready to be warned that this software is from an "unidentified developer". See https://support.apple.com/guide/mac-help/mh40616/mac

Contribute
----------

- Feel free to Star ⭐
- Share it with your friends
- Feel free to propose features and pull-requests
- And if you really love the project, feel free to sponsor and I might consider buying the Apple Developer Membership

Special Thanks
--------------

- [@Aisijin](https://github.com/Aisijin) for the App icons

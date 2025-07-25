# ScreenSaverMinimal

Template to create a macOS screen saver using Swift 5 (forked from https://github.com/mirkofetter/ScreenSaverMinimal with some code taken from Aerial https://github.com/JohnCoates/Aerial).

This project can be used as a starting point to create a macOS screen saver using Swift, as, as of Xcode 14 beta, Apple only provides a template for Objective-C screen savers. 

Please note that according to Apple, Swift screen savers are only officially supported as of macOS 14.6. There are **many** issues using Swift for screensavers on previous macOS versions (as an example, textfields won't work on High Sierra) so while you can support older versions, be aware there are many pitfalls. 

The template includes two targets, one that creates a usable `.saver`, and a test target that lets you quickly develop your screen saver without installing. 

## About Tahoe (macOS 26)

macOS 26 (Tahoe) introduced new issues with screen savers, particularly around the `isPreview` parameter behavior. Unlike previous versions where this bug could be worked around, the Tahoe bug currently has no known workaround.

For detailed information about known issues and potential solutions, see: [Tahoe screen saver discussion](https://github.com/JohnCoates/Aerial/issues/1396#issuecomment-3110063589)

## About Ventura

See here for a list of known issues with macOS Ventura, they relate mostly to the new System Settings app : [Ventura screen saver bugs on wiki](https://github.com/AerialScreensaver/ScreenSaverMinimal/wiki/Issues-with-macOS-Ventura-betas).

## About Catalina, Big Sur, .plugin and .appex

Starting with Catalina, the screen saver API is (in some aspects) deprecated, using the old (unsafe) plugin format. Most first party Apple screen savers are using a new App Extension format that, as of writing this, does not seem to be available yet to 3rd parties. 

Prior to Catalina, when compiling a screen saver as a `.saver`, you are compiling a plugin that will be used by either `Screen Saver Engine` or `System Preferences`, and run in their memory space. 

Starting with Catalina, your `.saver` will be a plugin to a system file called `legacyScreenSaver.appex` which itself is an extension to either `Screen Saver Engine` or `System Preferences`. 

There are two major implications to this, the first one is that your screen saver will run in a sandbox (for example, instead of `~/Library/Application Support`, this path will point to `~/Library/Containers/com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/Library/Application Support`). The second one is that your interactions with the system will be limited by `legacyScreenSaver.appex` entitlements. As of macOS 11 Big Sur, those are the current entitlements : 

```
com.apple.private.xpc.launchd.per-user-lookup
com.apple.security.app-sandbox
com.apple.security.cs.disable-library-validation
com.apple.security.files.user-selected.read-only
com.apple.security.network.client
com.apple.security.network.server
com.apple.security.temporary-exception.files.absolute-path.read-only
com.apple.security.temporary-exception.mach-lookup.global-name
com.apple.CARenderServer
com.apple.CoreDisplay.master
com.apple.nsurlstorage-cache
com.apple.ViewBridgeAuxiliary
com.apple.security.temporary-exception.sbpl
(allow mach-lookup mach-register)
com.apple.security.temporary-exception.yasb
```

Couple of examples of things you can't do, override the keyboard or read files outside of the system disk. 

Also note that you must sign and notarize your screen saver in order to be able to distribute it to other users.

## SwiftUI/Combine

This repository contains an experimental branch named `combine` that explores using SwiftUI with Combine for reactive state management in screen savers. The implementation includes:

- **ScreenSaverViewModel**: ObservableObject with Combine publishers for reactive data updates
- **SwiftUI ContentView**: Declarative UI with animations and state binding
- **NSHostingView Integration**: Bridge between SwiftUI and ScreenSaverView framework

**Current Status**: The SwiftUI implementation works correctly in the test app target but crashes when running as an actual screen saver. This suggests that SwiftUI may not be compatible with the screen saver framework's execution context, possibly due to:

- Sandboxing restrictions in `legacyScreenSaver.appex`
- SwiftUI runtime requirements that conflict with screen saver lifecycle
- NSHostingView incompatibilities with the screen saver drawing context

At this time, it may not be possible to reliably use SwiftUI in a screen saver context. The traditional AppKit/Core Graphics approach in the main branch remains the recommended implementation. 

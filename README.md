# react-native-receive-sharing-intent

A React Native plugin that enables receiving files and text from Android Share Intent or iOS Sharing Extension. 

**Disclaimer:** This package was build for a personal project and was not designed for general use in mind.
## Installation

```bash
$ yarn add https://github.com/shawnchin/react-native-receive-sharing-intent#<COMMIT_HASH>
```

## iOS

In `ios/<project_name>/info.plist`:
```xml

<plist version="1.0">
    <dict>
        <!-- .... -->
        <key>CFBundleURLTypes</key>
        <array>
            <dict>
                <key>CFBundleTypeRole</key>
                <string>Editor</string>
                <key>CFBundleURLSchemes</key>
                <array>
                    <string>YOUR_APP_PROTO</string>
                </array>
            </dict>
            <dict/>
        </array>

    </dict>
</plist>
```

In `ios/<project_name>/AppDelegate.mm`:
```objective-c
#import <React/RCTLinkingManager.h>
// ...

@implementation AppDelegate
// ...

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
  return [RCTLinkingManager application:application openURL:url options:options];
}

@end
```

### Creating Share Extension

1. In XCode, create a Share Extension ("File" -> "New" -> "Target").
2. Make sure the Minimum Deployment version (under General) of the Share Extension matches your main app.
3. Make sure the Code Signing Entitlements (under Build Settings) matches the main app

In `ios/<Share Extension Name>/info.plist`:
```xml

<plist version="1.0">
    <dict>
        <!-- ... -->
        <key>NSExtension</key>
        <dict>
            <key>NSExtensionAttributes</key>
            <dict>
                <key>PHSupportedMediaTypes</key>
                <array>
                    <!-- Add the following if you want to support sharing video into your app-->
                    <string>Video</string>
                    <!-- Add the following if you want to support sharing images into your app-->
                    <string>Image</string>
                </array>
                <key>NSExtensionActivationRule</key>
                <dict>
                    <!-- Add the following if you want to support sharing text into your app-->
                    <key>NSExtensionActivationSupportsText</key>
                    <true/>
                    <!-- Add the following if you want to support sharing urls into your app.-->
                    <key>NSExtensionActivationSupportsWebURLWithMaxCount</key>
                    <integer>1</integer>
                    <!-- Add the following if you want to support sharing images into your app-->
                    <key>NSExtensionActivationSupportsImageWithMaxCount</key>
                    <integer>100</integer>
                    <!-- Add the following if you want to support sharing video into your app-->
                    <key>NSExtensionActivationSupportsMovieWithMaxCount</key>
                    <integer>100</integer>
                    <!-- Add the following if you want to support sharing other files into your app-->
                    <key>NSExtensionActivationSupportsFileWithMaxCount</key>
                    <integer>100</integer>
                </dict>
            </dict>
            <key>NSExtensionMainStoryboard</key>
            <string>MainInterface</string>
            <key>NSExtensionPointIdentifier</key>
            <string>com.apple.share-services</string>
        </dict>

    </dict>
</plist>
```

In `ios/<Share Extension Name>/ShareViewController.swift`:
* Replace with content of [./shareExtension/ShareViewController.swift](./shareExtension/ShareViewController.swift)
* Update `hostAppBundleIdentifier`, `shareProtocol`, and `sharedKey` constants to match your app.

### Creating App Group
1. In XCode, create App Group (Under "Signing & Capabilities") for your main app. 
    * This **must** be `group.YOUR_APP_BUNDLE_IDENTIFIER` 
2. Create App Group with exactly the same name for the Share Extension
3. Make sure the entitlements used by both your debug and production builds, for both the app and Share Extension, contain:
    ```xml
     <key>com.apple.security.application-groups</key>
     <array>
        <string>group.YOUR_APP_BUNDLE_IDENTIFIER</string>
     </array>
    ```

## Android

TODO...

## Usage

TODO ...

## Acknowledgement

This package is based on [react-native-receive-sharing-intent](https://github.com/ajith-ab/react-native-receive-sharing-intent)

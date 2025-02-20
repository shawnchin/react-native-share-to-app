# react-native-share-to-app

A React Native plugin that enables receiving files and text from Android Share Intent or iOS Sharing Extension. 

**Disclaimer:** This package was build for a specific use case, and was not designed for general use in mind. 
It is based on [react-native-receive-sharing-intent](https://github.com/ajith-ab/react-native-receive-sharing-intent),
but with various customisations, e.g.:
* Shared images are compressed and resized
* Unused/inaccurate payload dropped
* Original file name is returned, while the returned file path is an intermediate file with a generated unique name.
* Misc compatibility and bug fixes
* Misc cleanup and refactoring

## Usage


```javascript
import ShareToApp from 'react-native-share-to-app';

// To subscribe share intent
ShareToApp.subscribeToSharedFiles(files => {
      /*
          files = [{
            filePath?: string;
            fileName?: string;
            mimeType?: string;  // android only
            subject?: string;
            text?: string;
            weblink?: string;
          }, ...]
      */
      console.log(files);  // add your handler here
   }, 
   (error) => {
      console.log(error);  // add your error handler here
   }, 
   'YOUR_APP_PROTO' 
);


// To clear Intents
ShareToApp.clearReceivedFiles();
```




## Installation

```bash
$ yarn add react-native-share-to-app
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

In `android/app/src/main/manifest.xml`:

```xml

<manifest xmlns:android="http://schemas.android.com/apk/res/android"
          package="com.example">
   <!-- ... -->

   <!-- TODO Add this Line  -->
   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>

   <application .... >
      <activity
         ....
         android:launchMode="singleTask"> <!--TODO IMPORTANT.set launchMode -> singleTask Recommended -->
      
         <!-- ... -->
         <intent-filter>
            <action android:name="android.intent.action.VIEW"/>
            <category android:name="android.intent.category.DEFAULT"/>
            <category android:name="android.intent.category.BROWSABLE"/>
            <!--TODO:  Add this filter, if you want support opening urls into your app-->
            <data
                    android:scheme="https"
                    android:host="example.com"
                    android:pathPrefix="/invite"/>
         </intent-filter>
      
         <!--TODO: Add this filter, if you want to support sharing text into your app-->
         <intent-filter>
            <action android:name="android.intent.action.SEND"/>
            <category android:name="android.intent.category.DEFAULT"/>
            <data android:mimeType="text/*"/>
         </intent-filter>
      
         <!--TODO: Add this filter, if you want to support sharing images into your app-->
         <intent-filter>
            <action android:name="android.intent.action.SEND"/>
            <category android:name="android.intent.category.DEFAULT"/>
            <data android:mimeType="image/*"/>
         </intent-filter>
      
         <intent-filter>
            <action android:name="android.intent.action.SEND_MULTIPLE"/>
            <category android:name="android.intent.category.DEFAULT"/>
            <data android:mimeType="image/*"/>
         </intent-filter>
      
         <!--TODO: Add this filter, if you want to support sharing videos into your app-->
         <intent-filter>
            <action android:name="android.intent.action.SEND"/>
            <category android:name="android.intent.category.DEFAULT"/>
            <data android:mimeType="video/*"/>
         </intent-filter>
         <intent-filter>
            <action android:name="android.intent.action.SEND_MULTIPLE"/>
            <category android:name="android.intent.category.DEFAULT"/>
            <data android:mimeType="video/*"/>
         </intent-filter>
      
         <!--TODO: Add this filter, if you want to support sharing any type of files-->
         <intent-filter>
            <action android:name="android.intent.action.SEND"/>
            <category android:name="android.intent.category.DEFAULT"/>
            <data android:mimeType="*/*"/>
         </intent-filter>
         <intent-filter>
            <action android:name="android.intent.action.SEND_MULTIPLE"/>
            <category android:name="android.intent.category.DEFAULT"/>
            <data android:mimeType="*/*"/>
         </intent-filter>
      
         <!-- ... -->
      
      </activity>
    </application>
</manifest>  
```

In `android/app/src/main/java/com/YOUR_APP/MainActivity.java`:
```java
// on top of your file
import android.content.Intent;

// ...

public class MainActivity extends ReactActivity {
   // ...
   
   // add to your MainActivity Class body
   @Override
   public void onNewIntent(Intent intent) {
     super.onNewIntent(intent);
     setIntent(intent);
   }
}
```


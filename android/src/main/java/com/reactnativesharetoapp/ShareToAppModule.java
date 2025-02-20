package com.reactnativesharetoapp;

import android.app.Activity;
import android.app.Application;
import android.content.Intent;


import android.os.Build;

import androidx.annotation.RequiresApi;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;


public class ShareToAppModule extends ReactContextBaseJavaModule {
    public final String Log_Tag = "ShareToApp";

    private final ReactApplicationContext reactContext;
    private ShareToAppHelper shareToAppHelper;

    public ShareToAppModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
        Application applicationContext = (Application) reactContext.getApplicationContext();
        shareToAppHelper = new ShareToAppHelper(applicationContext);
    }


    protected void onNewIntent(Intent intent) {
        Activity mActivity = getCurrentActivity();
        if (mActivity == null) {
            return;
        }
        mActivity.setIntent(intent);
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    @ReactMethod
    public void getFileNames(Promise promise) {
        Activity mActivity = getCurrentActivity();
        if (mActivity == null) {
            return;
        }
        Intent intent = mActivity.getIntent();
        shareToAppHelper.sendFileNames(reactContext, intent, promise);
        // mActivity.setIntent(null);
    }

    @ReactMethod
    public void clearFileNames() {
        Activity mActivity = getCurrentActivity();
        if (mActivity == null) {
            return;
        }
        Intent intent = mActivity.getIntent();
        if (intent != null) {
            shareToAppHelper.clearFileNames(intent);
        }
    }


    @Override
    public String getName() {
        return "ShareToApp";
    }
}

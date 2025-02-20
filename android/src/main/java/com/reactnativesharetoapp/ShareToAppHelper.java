package com.reactnativesharetoapp;

import android.app.Application;
import android.content.ContentResolver;
import android.content.Context;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.util.Log;
import android.webkit.URLUtil;
import android.os.Build;
import android.provider.OpenableColumns;

import androidx.annotation.RequiresApi;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeMap;

import java.io.File;
import java.net.URLConnection;
import java.util.ArrayList;
import java.util.Objects;

public class ShareToAppHelper {

    private Context context;

    public ShareToAppHelper(Application context) {
        this.context = context;
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    public void sendFileNames(Context context, Intent intent, Promise promise) {
        if (intent == null) {
            promise.reject("error", "Null intent.");
        }
        try {
            String action = intent.getAction();
            String type = intent.getType();
            if (type == null) {
                return;
            }
            if (!type.startsWith("text") && (Objects.equals(action, Intent.ACTION_SEND) || Objects.equals(action, Intent.ACTION_SEND_MULTIPLE))) {
                WritableMap files = handleMediaIntent(intent, context);
                if (files == null) return;
                promise.resolve(files);
            } else if (type.startsWith("text") && Objects.equals(action, Intent.ACTION_SEND)) {
                String text = null;
                String subject = null;
                try {
                    text = intent.getStringExtra(Intent.EXTRA_TEXT);
                    subject = intent.getStringExtra(Intent.EXTRA_SUBJECT);
                } catch (Exception ignored) {
                }
                if (text == null) {
                    WritableMap files = handleMediaIntent(intent, context);
                    if (files == null) return;
                    promise.resolve(files);
                } else {
                    WritableMap files = new WritableNativeMap();
                    boolean textIsUrl = URLUtil.isValidUrl(text);
                    String outText = textIsUrl ? null : text;
                    String outWeblink = textIsUrl ? text : null;
                    files.putMap("0", createTextOutput(outText, outWeblink, subject));
                    promise.resolve(files);
                }

            } else if (Objects.equals(action, Intent.ACTION_VIEW)) {
                String link = intent.getDataString();
                WritableMap files = new WritableNativeMap();
                files.putMap("0", createTextOutput(null, link, null));
                promise.resolve(files);
            } else if (Objects.equals(action, "android.intent.action.PROCESS_TEXT")) {
                String text = null;
                try {
                    text = intent.getStringExtra(intent.EXTRA_PROCESS_TEXT);
                } catch (Exception e) {
                }
                WritableMap files = new WritableNativeMap();
                files.putMap("0", createTextOutput(text, null, null));
                promise.resolve(files);
            } else {
                promise.reject("error", "Invalid file type.");
            }
        } catch (Exception e) {
            promise.reject("error", e.toString());
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    public WritableMap handleMediaIntent(Intent intent, Context context) {
        if (intent == null) return null;

        String subject = null;
        try {
            subject = intent.getStringExtra(Intent.EXTRA_SUBJECT);
        } catch (Exception ignored) {
        }

        WritableMap files = new WritableNativeMap();
        if (Objects.equals(intent.getAction(), Intent.ACTION_SEND)) {
            Uri contentUri = (Uri) intent.getParcelableExtra(Intent.EXTRA_STREAM);
            if (contentUri == null) return null;
            try {
              files.putMap("0", extractMediaContent(contentUri, context, subject));
            } catch (Exception e) {
              Log.w("ShareToApp", "Error extracting media", e);
              return null;
            }

        } else if (Objects.equals(intent.getAction(), Intent.ACTION_SEND_MULTIPLE)) {
            ArrayList<Uri> contentUris = intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM);
            if (contentUris != null) {
                int index = 0;
                for (Uri uri : contentUris) {
                    try {
                      files.putMap(Integer.toString(index), extractMediaContent(uri, context, subject));
                    } catch (Exception e) {
                      Log.w("ShareToApp", "Error extracting media", e);
                      return null;
                    }

                    index++;
                }
            }
        }
        return files;
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    private WritableMap extractMediaContent(Uri contentUri, Context context, String subject) throws Exception {
        String filePath = FileDirectory.INSTANCE.getAbsolutePath(context, contentUri);
        ContentResolver contentResolver = context.getContentResolver();
        Cursor queryResult = contentResolver.query(contentUri, null, null, null, null);
        queryResult.moveToFirst();
        String fileName = queryResult.getString(queryResult.getColumnIndex(OpenableColumns.DISPLAY_NAME));

        String mimeType = contentResolver.getType(contentUri);
        if (mimeType.startsWith("image/")) {
          Compression compression = new Compression();
          File compressImage = compression.compressImage(context, filePath);
          filePath = compressImage.getPath();
          fileName = replaceExtension(fileName, getExtension(filePath));  // compression will change file type
        }
        return createMediaOutput(fileName, filePath, contentUri.toString(), subject);
    }

    private WritableMap createMediaOutput(String fileName, String filePath, String contentUri, String subject) {
        WritableMap outputMap = new WritableNativeMap();
        outputMap.putString("contentUri", contentUri);
        outputMap.putString("filePath", filePath);
        outputMap.putString("fileName", fileName);
        outputMap.putString("weblink", null);
        outputMap.putString("text", null);
        outputMap.putString("subject", subject);
        return outputMap;
    }

    private WritableMap createTextOutput(String text, String weblink, String subject) {
        WritableMap outputMap = new WritableNativeMap();
        outputMap.putString("contentUri", null);
        outputMap.putString("filePath", null);
        outputMap.putString("fileName", null);
        outputMap.putString("weblink", weblink);
        outputMap.putString("text", text);
        outputMap.putString("subject", subject);
        return outputMap;
    }

    private String getMediaType(String url) {
        String mimeType = URLConnection.guessContentTypeFromName(url);
        return mimeType;
    }


    public void clearFileNames(Intent intent) {
        if (intent == null) return;
        String type = intent.getType();
        if (type == null) return;
        if (type.startsWith("text")) {
            intent.removeExtra(Intent.EXTRA_TEXT);
        } else if (type.startsWith("image") || type.startsWith("video") || type.startsWith("application")) {
            intent.removeExtra(Intent.EXTRA_STREAM);
        }
    }

    public String getFileName(String file) {
        return file.substring(file.lastIndexOf('/') + 1);
    }

    public String getExtension(String file) {
        return file.substring(file.lastIndexOf('.') + 1);
    }

    public String replaceExtension(String file, String ext) {
        return file.substring(0, file.lastIndexOf('.') + 1).concat(ext);
    }

}

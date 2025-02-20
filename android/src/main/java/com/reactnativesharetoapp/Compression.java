package com.reactnativesharetoapp;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.media.ExifInterface;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.util.UUID;


class Compression {
    public static final int compressionQuality = 50; // 0-100
    public static final int maxImageDim = 1200;

    File compressImage(Context context, final String imagePath) throws Exception, IOException, OutOfMemoryError {
        // Validate image and get dims
        BitmapFactory.Options imageProps = validateImage(imagePath);
        int imageWidth = imageProps.outWidth;
        int imageHeight = imageProps.outHeight;

        // Calculate required scaling
        ScalingProps scaling = new ScalingProps(imageProps.outWidth, imageProps.outHeight, maxImageDim, maxImageDim);
        BitmapFactory.Options samplingOptions = new BitmapFactory.Options();
        samplingOptions.inSampleSize = scaling.sampleSize;

        // Read in image
        Bitmap bitmap = BitmapFactory.decodeFile(imagePath, samplingOptions);

        // Use original image exif orientation data to preserve image orientation for the resized bitmap
        ExifInterface originalExif = new ExifInterface(imagePath);
        String originalOrientation = originalExif.getAttribute(ExifInterface.TAG_ORIENTATION);

        // Rescale bitmap and write to app cache as compressed JPG
        bitmap = Bitmap.createScaledBitmap(bitmap, scaling.width, scaling.height, true);
        File outDir = context.getCacheDir();
        File outFile = new File(outDir, UUID.randomUUID() + ".jpg");
        OutputStream os = new BufferedOutputStream(new FileOutputStream(outFile));
        bitmap.compress(Bitmap.CompressFormat.JPEG, compressionQuality, os);
        // Don't set unnecessary exif attribute
        if (shouldSetOrientation(originalOrientation)) {
            ExifInterface exif = new ExifInterface(outFile.getAbsolutePath());
            exif.setAttribute(ExifInterface.TAG_ORIENTATION, originalOrientation);
            exif.saveAttributes();
        }

        os.close();
        bitmap.recycle();

        return outFile;
    }

    private BitmapFactory.Options validateImage(String path) throws Exception {
        BitmapFactory.Options options = new BitmapFactory.Options();
        options.inJustDecodeBounds = true; // get image attributes without loading image in mem
        options.inPreferredConfig = Bitmap.Config.RGB_565;
        options.inDither = true;

        BitmapFactory.decodeFile(path, options); // returns null and updates options because inJustDecodeBounds

        if (options.outMimeType == null || options.outWidth == 0 || options.outHeight == 0) {
            throw new Exception("Invalid image provided");
        }

        return options;
    }

    private boolean shouldSetOrientation(String orientation) {
        return !orientation.equals(String.valueOf(ExifInterface.ORIENTATION_NORMAL))
                && !orientation.equals(String.valueOf(ExifInterface.ORIENTATION_UNDEFINED));
    }
}

class ScalingProps {
    float scale;
    int width;
    int height;

    // sampleSize determines subsampling ratio to reduce size of original image.
    // Value has to be a power of 2.
    // https://learn.microsoft.com/en-us/dotnet/api/android.graphics.bitmapfactory.options.insamplesize?view=net-android-34.0
    int sampleSize;

    public ScalingProps(int originalWidth, int originalHeight, int maxWidth, int maxHeight) {
        scale = Math.max((float)originalWidth / maxWidth, (float)originalHeight / maxHeight);

        if (scale <= 1) {
            sampleSize = 1;
            scale = 1;
            width = originalWidth;
            height = originalHeight;
        } else {
            sampleSize = 2;
            while (sampleSize < scale) {
                sampleSize *= 2;
            }
            width = Math.round(originalWidth / scale);
            height = Math.round(originalHeight / scale);
        }
    }
}

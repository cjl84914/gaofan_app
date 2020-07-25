package com.geetion.gaofan;

import android.app.Activity;
import android.app.ActivityManager;
import android.content.Context;
import android.content.res.AssetFileDescriptor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Matrix;
import android.os.AsyncTask;
import android.os.SystemClock;
import android.util.Log;

import org.tensorflow.lite.Interpreter;
import org.tensorflow.lite.gpu.GpuDelegate;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;
import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.view.FlutterMain;

public class StylePlugin implements MethodCallHandler {

    private Activity activity;
    public static String CHANNEL = "tflite";
    private Interpreter interpreterPredict;
    private Interpreter interpreterTransform;
    private boolean tfLiteBusy = false;
    private static MethodChannel channel;
    int CONTENT_SIZE = 512;

    private StylePlugin(Activity activity) {
        this.activity = activity;
        ActivityManager manager = (ActivityManager) activity.getSystemService(Context.ACTIVITY_SERVICE);
        ActivityManager.MemoryInfo info = new ActivityManager.MemoryInfo();
        manager.getMemoryInfo(info);
        boolean isLowMem = (info.totalMem < 3000L * 1000L * 1000L) ? true : false;
        try {
            if (isLowMem) {
                CONTENT_SIZE = 384;
                interpreterPredict = loadModel("assets/style_predict_quantized_256.tflite", true, 4, true);
                interpreterTransform = loadModel("assets/style_transfer_quantized_384.tflite", true, 4, false);
            } else {
                interpreterPredict = loadModel("assets/style_predict.tflite", true, 4, true);
                interpreterTransform = loadModel("assets/style_transform_quantized_512.tflite", true, 4, false);
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static void registerWith(FlutterEngine flutterEngine, Activity activity) {
        StylePlugin instance = new StylePlugin(activity);
        channel = new MethodChannel(flutterEngine.getDartExecutor(), CHANNEL);
        channel.setMethodCallHandler(instance);
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {  // 分析 2
        if (call.method.equals("runStyleOnImage")) {
            try {
                new RunStyleOnImage((HashMap) call.arguments, result).executeTfliteTask();
            } catch (Exception e) {
                result.error("Failed to run model", e.getMessage(), e);
            }
        } else if (call.method.equals("close")) {
            close();
        } else {
            result.notImplemented();
        }
    }


    private class RunStyleOnImage extends TfliteTask {
        String path, outputType, style, ratio;
        float IMAGE_MEAN, IMAGE_STD;
        long startTime;
        int STYLE_SIZE = 256;
        Object[] inputsForPredict, inputsForStyleTransfer, inputContentPredict;
        Map<Integer, Object> outputsForPredict = new HashMap<>();
        Map<Integer, Object> outputsForStyleTransfer = new HashMap<>();
        Map<Integer, Object> outputsForContentPredict = new HashMap<>();
        ByteBuffer contentByte, styleByte, contentByte256;

        RunStyleOnImage(HashMap args, MethodChannel.Result result) throws IOException {
            super(args, result);
            double mean = (double) (args.get("imageMean"));
            IMAGE_MEAN = (float) mean;
            double std = (double) (args.get("imageStd"));
            IMAGE_STD = (float) std;
            outputType = args.get("outputType").toString();
            startTime = SystemClock.uptimeMillis();
            //内容图片
            path = args.get("path").toString();
            style = args.get("style").toString();
            ratio = args.get("ratio").toString();

            InputStream inputStream = new FileInputStream(path.replace("file://", ""));
            Bitmap contentImage = BitmapFactory.decodeStream(inputStream);
            contentByte = bitmapToByteBuffer(contentImage, CONTENT_SIZE, CONTENT_SIZE, IMAGE_MEAN, IMAGE_STD);
            contentByte256 = bitmapToByteBuffer(contentImage, STYLE_SIZE, STYLE_SIZE, IMAGE_MEAN, IMAGE_STD);
            //风格图片
            String key = FlutterMain.getLookupKeyForAsset(style);
            Bitmap styleBitmap = BitmapFactory.decodeStream( activity.getAssets().open(key));
            styleByte = bitmapToByteBuffer(styleBitmap, STYLE_SIZE, STYLE_SIZE, IMAGE_MEAN, IMAGE_STD);
            inputsForPredict = new Object[]{styleByte};
            inputContentPredict = new Object[]{contentByte256};
            outputsForPredict.put(0, new float[1][1][1][100]);
            outputsForStyleTransfer.put(0, new float[1][CONTENT_SIZE][CONTENT_SIZE][3]);
            outputsForContentPredict.put(0, new float[1][1][1][100]);
        }

        protected void runTflite() {
            /**
             * 1. style + predict > style_bottlenect
             * 2. content + predict > content_bottlenect
             * 3. style_bottlenect + content_bottlenect > bottlenect_blended
             * 4. content + bottlenect + transfer > result
             */
            interpreterPredict.runForMultipleInputsOutputs(inputsForPredict, outputsForPredict);
            float[][][][] style_bottleneck = (float[][][][]) outputsForPredict.get(0);
            interpreterPredict.runForMultipleInputsOutputs(inputContentPredict, outputsForContentPredict);
            float[][][][] content_bottleneck = (float[][][][]) outputsForContentPredict.get(0);
            float content_blending_ratio = Float.valueOf(ratio);
            float[][][][] style_bottleneck_blended = new float[1][1][1][100];
            for (int i = 0; i < content_bottleneck[0][0][0].length; i++) {
                style_bottleneck_blended[0][0][0][i] = (1 - content_blending_ratio) * content_bottleneck[0][0][0][i] + content_blending_ratio * style_bottleneck[0][0][0][i];
            }
            inputsForStyleTransfer = new Object[]{contentByte, style_bottleneck_blended};
            interpreterTransform.runForMultipleInputsOutputs(inputsForStyleTransfer, outputsForStyleTransfer);
        }

        protected void onRunTfliteDone() {
            Log.v("time", "Inference took " + (SystemClock.uptimeMillis() - startTime));
            Bitmap bitmapRaw = convertArrayToBitmap((float[][][][]) outputsForStyleTransfer.get(0), CONTENT_SIZE, CONTENT_SIZE);
            Map<String, Object> res = new HashMap<>();
            if (outputType.equals("png")) {
                res.put("img", compressPNG(bitmapRaw));
            } else {
                res.put("img", bitmapRaw);
            }
            result.success(res);
        }
    }

    ByteBuffer bitmapToByteBuffer(
            Bitmap bitmapIn,
            int width,
            int height,
            float mean,
            float std
    ) {
        Bitmap bitmap = bitmapIn;
        if (bitmapIn.getWidth() != width || bitmapIn.getHeight() != height) {
            Matrix matrix = getTransformationMatrix(bitmapIn.getWidth(), bitmapIn.getHeight(),
                    width, height, true);
            bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
            final Canvas canvas = new Canvas(bitmap);
            canvas.drawBitmap(bitmapIn, matrix, null);
        }
        ByteBuffer inputImage = ByteBuffer.allocateDirect(1 * width * height * 3 * 4);
        inputImage.order(ByteOrder.nativeOrder());
        inputImage.rewind();
        for (int y = 0; y < height; ++y) {
            for (int x = 0; x < width; ++x) {
                int value = bitmap.getPixel(x, y);
                // Normalize channel values to [-1.0, 1.0]. This requirement varies by
                // model. For example, some models might require values to be normalized
                // to the range [0.0, 1.0] instead.
                inputImage.putFloat(((value >> 16 & 0xFF) - mean) / std);
                inputImage.putFloat(((value >> 8 & 0xFF) - mean) / std);
                inputImage.putFloat(((value & 0xFF) - mean) / std);
            }
        }
        inputImage.rewind();
        return inputImage;
    }

    private static Matrix getTransformationMatrix(final int srcWidth,
                                                  final int srcHeight,
                                                  final int dstWidth,
                                                  final int dstHeight,
                                                  final boolean maintainAspectRatio) {
        final Matrix matrix = new Matrix();
        if (srcWidth != dstWidth || srcHeight != dstHeight) {
            final float scaleFactorX = dstWidth / (float) srcWidth;
            final float scaleFactorY = dstHeight / (float) srcHeight;
            if (maintainAspectRatio) {
                final float scaleFactor = Math.max(scaleFactorX, scaleFactorY);
                matrix.postScale(scaleFactor, scaleFactor);
            } else {
                matrix.postScale(scaleFactorX, scaleFactorY);
            }
        }
        matrix.invert(new Matrix());
        return matrix;
    }

    private Bitmap convertArrayToBitmap(float[][][][] imageArray, int imageWidth, int imageHeight) {
        Bitmap.Config conf = Bitmap.Config.ARGB_8888;
        Bitmap styledImage = Bitmap.createBitmap(imageWidth, imageHeight, conf);
        int x = 0;
        for (int var7 = imageArray[0].length; x < var7; ++x) {
            int y = 0;

            for (int var9 = imageArray[0][0].length; y < var9; ++y) {
                int color = Color.rgb((int) (imageArray[0][x][y][0] * (float) 255), (int) (imageArray[0][x][y][1] * (float) 255), (int) (imageArray[0][x][y][2] * (float) 255));
                styledImage.setPixel(y, x, color);
            }
        }
        return styledImage;
    }

    byte[] compressPNG(Bitmap bitmap) {
        // https://stackoverflow.com/questions/4989182/converting-java-bitmap-to-byte-array#4989543
        ByteArrayOutputStream stream = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream);
        byte[] byteArray = stream.toByteArray();
        // bitmap.recycle();
        return byteArray;
    }

    private Interpreter loadModel(String model, Boolean isAssetObj, int numThreads, boolean isGPU) throws IOException {
        boolean isAsset = isAssetObj == null ? false : (boolean) isAssetObj;
        MappedByteBuffer buffer = null;
        if (isAsset) {
            String key = FlutterMain.getLookupKeyForAsset(model);
            AssetFileDescriptor fileDescriptor =  activity.getAssets().openFd(key);
            FileInputStream inputStream = new FileInputStream(fileDescriptor.getFileDescriptor());
            FileChannel fileChannel = inputStream.getChannel();
            long startOffset = fileDescriptor.getStartOffset();
            long declaredLength = fileDescriptor.getDeclaredLength();
            buffer = fileChannel.map(FileChannel.MapMode.READ_ONLY, startOffset, declaredLength);
        } else {
            FileInputStream inputStream = new FileInputStream(new File(model));
            FileChannel fileChannel = inputStream.getChannel();
            long declaredLength = fileChannel.size();
            buffer = fileChannel.map(FileChannel.MapMode.READ_ONLY, 0, declaredLength);
        }
        final Interpreter.Options tfliteOptions = new Interpreter.Options();
        tfliteOptions.setNumThreads(numThreads);
        //use gpu
        if (isGPU) {
            GpuDelegate gpuDelegate = new GpuDelegate();
            tfliteOptions.addDelegate(gpuDelegate);
        }
        return new Interpreter(buffer, tfliteOptions);
    }

    private abstract class TfliteTask extends AsyncTask<Void, Void, Void> {
        MethodChannel.Result result;
        boolean asynch;

        TfliteTask(HashMap args, MethodChannel.Result result) {
            if (tfLiteBusy) throw new RuntimeException("Interpreter busy");
            else tfLiteBusy = true;
            Object asynch = args.get("asynch");
            this.asynch = asynch == null ? false : (boolean) asynch;
            this.result = result;
        }

        abstract void runTflite();

        abstract void onRunTfliteDone();

        public void executeTfliteTask() {
            if (asynch) execute();
            else {
                runTflite();
                tfLiteBusy = false;
                onRunTfliteDone();
            }
        }

        protected Void doInBackground(Void... backgroundArguments) {
            runTflite();
            return null;
        }

        protected void onPostExecute(Void backgroundResult) {
            tfLiteBusy = false;
            onRunTfliteDone();
        }
    }

    private void close() {
        if (interpreterPredict != null)
            interpreterPredict.close();
        if (interpreterTransform != null)
            interpreterTransform.close();
    }
}
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

class Tflite {
  static const MethodChannel _channel = const MethodChannel('tflite');
  static Future<Map> runStyleOnImage(
      {@required String path,
        @required int style,
        double imageMean = 0,
        double imageStd = 255.0,
        double ratio = 1,
        String outputType = "png",
        bool asynch = true}) async {
    return await _channel.invokeMethod(
      'runStyleOnImage',
      {
        "path": path,
        "style": style,
        "ratio": ratio,
        "imageMean": imageMean,
        "imageStd": imageStd,
        "asynch": asynch,
        "outputType": outputType
      },
    );
  }


  static Future close() async {
    return await _channel.invokeMethod('close');
  }

}

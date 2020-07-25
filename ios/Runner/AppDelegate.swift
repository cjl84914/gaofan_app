import Flutter

import TensorFlowLite


@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        
        self.interpreterPredict = loadModel(assetPath:"assets/style_predict_quantized_256")
        self.interpreterTransform = loadModel(assetPath:"assets/style_transfer_quantized_384")
        
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController;
        let batteryChannel = FlutterMethodChannel.init(name: "tflite", binaryMessenger: controller.binaryMessenger);
        batteryChannel.setMethodCallHandler { (call, result) in
            if("runStyleOnImage" == call.method){
                runStyleOnImage(args:call.arguments as! NSDictionary, result:result)
            }else{
                result(FlutterMethodNotImplemented);
            }
        }
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private var interpreterPredict:Interpreter?
    private var interpreterTransform:Interpreter?
}

func runStyleOnImage(args:NSDictionary, result:FlutterResult) {
    let path = args["path"]
    //let style = args["style"]
    //let input_mean = args["imageMean"]
    //let input_std = args["imageStd"]
    //  let NSString* outputType = args[@"outputType"];
    //  const NSString* ratio = args[@"ratio"];
    let targetImage = UIImage(contentsOfFile:path as! String)

    let inputRGBData = targetImage?.scaledData(
        with: Constants.inputImageSize,
        isQuantized: false
    )
    print(inputRGBData)
}

private func postprocessImageData(data: Data,
                                  size: CGSize = Constants.inputImageSize) -> CGImage? {
  let width = Int(size.width)
  let height = Int(size.height)

    let floats = data.toArray(type: Float32.self)

  let bufferCapacity = width * height * 4
  let unsafePointer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferCapacity)
  let unsafeBuffer = UnsafeMutableBufferPointer<UInt8>(start: unsafePointer,
                                                       count: bufferCapacity)
  defer {
    unsafePointer.deallocate()
  }

  for x in 0 ..< width {
    for y in 0 ..< height {
      let floatIndex = (y * width + x) * 3
      let index = (y * width + x) * 4
      let red = UInt8(floats[floatIndex] * 255)
      let green = UInt8(floats[floatIndex + 1] * 255)
      let blue = UInt8(floats[floatIndex + 2] * 255)

      unsafeBuffer[index] = red
      unsafeBuffer[index + 1] = green
      unsafeBuffer[index + 2] = blue
      unsafeBuffer[index + 3] = 0
    }
  }

  let outData = Data(buffer: unsafeBuffer)

  // Construct image from output tensor data
  let alphaInfo = CGImageAlphaInfo.noneSkipLast
  let bitmapInfo = CGBitmapInfo(rawValue: alphaInfo.rawValue)
      .union(.byteOrder32Big)
  let colorSpace = CGColorSpaceCreateDeviceRGB()
  guard
    let imageDataProvider = CGDataProvider(data: outData as CFData),
    let cgImage = CGImage(
      width: width,
      height: height,
      bitsPerComponent: 8,
      bitsPerPixel: 32,
      bytesPerRow: MemoryLayout<UInt8>.size * 4 * Int(Constants.inputImageSize.width),
      space: colorSpace,
      bitmapInfo: bitmapInfo,
      provider: imageDataProvider,
      decode: nil,
      shouldInterpolate: false,
      intent: .defaultIntent
    )
    else {
      return nil
  }
  return cgImage
}

func loadModel(assetPath: String) -> Interpreter?{
    let modelFilename = FlutterDartProject.lookupKey(forAsset: assetPath)
    guard let modelPath = Bundle.main.path(
         forResource: modelFilename,
         ofType: "tflite"
       ) else {
         print("Failed to load the model file with name: \(modelFilename).")
         return nil
    }
    var options = Interpreter.Options()
    options.threadCount = 1
    do {
        // Create the `Interpreter`.
        let interpreter = try Interpreter(modelPath: modelPath, options: options)
        // Allocate memory for the model's input `Tensor`s.
        try interpreter.allocateTensors()
        return interpreter
    } catch let error {
        print("Failed to create the interpreter with error: \(error.localizedDescription)")
    }
    return nil
}

enum StyleTransferError: Error {
  // Invalid input image
  case invalidImage

  // TF Lite Internal Error when initializing
  case internalError(Error)

  // Invalid input image
  case resultVisualizationError
}

private enum Constants {
  static let styleImageSize = CGSize(width: 256, height: 256)
  static let inputImageSize = CGSize(width: 384, height: 384)
}




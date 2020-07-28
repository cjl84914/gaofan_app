import Flutter
import TensorFlowLite
import Bugly

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    private var cpuStyleTransferer: StyleTransferer?
    private var gpuStyleTransferer: StyleTransferer?
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let config = BuglyConfig()
        config.debugMode = false
        Bugly.start(withAppId: "88f5a49cfe", config:config)
        GeneratedPluginRegistrant.register(with: self)
        
        StyleTransferer.newCPUStyleTransferer { result in
            switch result {
            case .success(let transferer):
                self.cpuStyleTransferer = transferer
            case .error(let wrappedError):
                print("Failed to initialize: \(wrappedError)")
            }
        }
        
        StyleTransferer.newGPUStyleTransferer { result in
            switch result {
            case .success(let transferer):
                self.gpuStyleTransferer = transferer
            case .error(let wrappedError):
                print("Failed to initialize: \(wrappedError)")
            }
        }
        
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController;
        let channel = FlutterMethodChannel.init(name: "tflite", binaryMessenger: controller.binaryMessenger);
        channel.setMethodCallHandler { (call, rs) in
            if("runStyleOnImage" == call.method){
                let args = call.arguments as! NSDictionary
                let imgPath = args["path"]
                let stylePath = args["style"]
                let ratio = args["ratio"]
                let image = UIImage(contentsOfFile:imgPath as! String)
                let key = FlutterDartProject.lookupKey(forAsset: stylePath as! String)
                let styleImage = UIImage(named: key)
                self.gpuStyleTransferer?.runStyleTransfer(
                    style: styleImage!,
                    image: image!,
                    ratio: ratio as! Double,
                    completion: { result in
                        // Show the result on screen
                        switch result {
                        case let .success(styleTransferResult):
                            let png = styleTransferResult.resultImage.pngData()
                            let map:Dictionary = ["img":png]
                            rs(map)
                        case let .error(error):
                            print(error.localizedDescription)
                        }
                        
                })
            }else{
                rs(FlutterMethodNotImplemented);
            }
        }
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

}




#define TFLITE2

#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"

#include <pthread.h>
#include <unistd.h>
#include <fstream>
#include <iostream>
#include <queue>
#include <sstream>
#include <string>

#import "TFLTensorFlowLite.h"
#ifdef CONTRIB_PATH
#include "tensorflow/contrib/lite/kernels/register.h"
#include "tensorflow/contrib/lite/model.h"
#include "tensorflow/contrib/lite/string_util.h"
#include "tensorflow/contrib/lite/op_resolver.h"
#elif defined TFLITE2
#import "TensorFlowLiteC.h"
#import "metal_delegate.h"
#else
#include "tensorflow/lite/kernels/register.h"
#include "tensorflow/lite/model.h"
#include "tensorflow/lite/string_util.h"
#include "tensorflow/lite/op_resolver.h"
#endif

#include "ios_image_load.h"

#define LOG(x) std::cerr

typedef void (^TfLiteStatusCallback)(TfLiteStatus);
NSString* loadModel(NSObject<FlutterPluginRegistrar>* _registrar, NSDictionary* args);
void runTflite(NSDictionary* args, TfLiteStatusCallback cb);
void runModelOnImage(NSDictionary* args, FlutterResult result);

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  // Override point for customization after application launch.

  FlutterViewController* controller = (FlutterViewController*)self.window.rootViewController;
    FlutterMethodChannel* batteryChannel = [FlutterMethodChannel
                                              methodChannelWithName:@"tflite"
                                              binaryMessenger:controller];

      [batteryChannel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
      if ([@"runModelOnImage" isEqualToString:call.method]) {
        runModelOnImage(call.arguments, result);
      } else {
          result(FlutterMethodNotImplemented);
      }
     }];
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end

std::vector<std::string> labels;
#ifdef TFLITE2
TfLiteInterpreter *interpreter = nullptr;
TfLiteModel *model = nullptr;
TfLiteDelegate *delegate = nullptr;
#else
std::unique_ptr<tflite::FlatBufferModel> model;
std::unique_ptr<tflite::Interpreter> interpreter;
#endif
bool interpreter_busy = false;

static void LoadLabels(NSString* labels_path,
                       std::vector<std::string>* label_strings) {
  if (!labels_path) {
    LOG(ERROR) << "Failed to find label file at" << labels_path;
  }
  std::ifstream t;
  t.open([labels_path UTF8String]);
  label_strings->clear();
  for (std::string line; std::getline(t, line); ) {
    label_strings->push_back(line);
  }
  t.close();
}

NSString* loadModel(NSObject<FlutterPluginRegistrar>* _registrar, NSDictionary* args) {
  NSString* graph_path;
  NSString* key;
  NSNumber* isAssetNumber = args[@"isAsset"];
  bool isAsset = [isAssetNumber boolValue];
  if(isAsset){
    key = [_registrar lookupKeyForAsset:args[@"model"]];
    graph_path = [[NSBundle mainBundle] pathForResource:key ofType:nil];
  }else{
    graph_path = args[@"model"];
  }

  const int num_threads = [args[@"numThreads"] intValue];
  
#ifdef TFLITE2
  TfLiteInterpreterOptions *options = nullptr;
  model = TfLiteModelCreateFromFile(graph_path.UTF8String);
  if (!model) {
    return [NSString stringWithFormat:@"%s %@", "Failed to mmap model", graph_path];
  }
  options = TfLiteInterpreterOptionsCreate();
  TfLiteInterpreterOptionsSetNumThreads(options, num_threads);
  
  bool useGpuDelegate = [args[@"useGpuDelegate"] boolValue];
  if (useGpuDelegate) {
    delegate = TFLGpuDelegateCreate(nullptr);
    TfLiteInterpreterOptionsAddDelegate(options, delegate);
  }
#else
  model = tflite::FlatBufferModel::BuildFromFile([graph_path UTF8String]);
  if (!model) {
    return [NSString stringWithFormat:@"%s %@", "Failed to mmap model", graph_path];
  }
  LOG(INFO) << "Loaded model " << graph_path;
  model->error_reporter();
  LOG(INFO) << "resolved reporter";
#endif
  
  if ([args[@"labels"] length] > 0) {
    NSString* labels_path;
    if(isAsset){
      key = [_registrar lookupKeyForAsset:args[@"labels"]];
      labels_path = [[NSBundle mainBundle] pathForResource:key ofType:nil];
    }else{
      labels_path = args[@"labels"];
    }
    LoadLabels(labels_path, &labels);
  }

#ifdef TFLITE2
  interpreter = TfLiteInterpreterCreate(model, options);
  if (!interpreter) {
    return @"Failed to construct interpreter";
  }
  
  if (TfLiteInterpreterAllocateTensors(interpreter) != kTfLiteOk) {
     return @"Failed to allocate tensors!";
   }
#else
  tflite::ops::builtin::BuiltinOpResolver resolver;
  tflite::InterpreterBuilder(*model, resolver)(&interpreter);
  if (!interpreter) {
    return @"Failed to construct interpreter";
  }
  
  if (interpreter->AllocateTensors() != kTfLiteOk) {
    return @"Failed to allocate tensors!";
  }
  
  if (num_threads != -1) {
    interpreter->SetNumThreads(num_threads);
  }
  #endif
  
  return @"success";
}

void runTflite(NSDictionary* args, TfLiteStatusCallback cb) {
  const bool asynch = [args[@"asynch"] boolValue];
  if (asynch) {
    interpreter_busy = true;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
#ifdef TFLITE2
      TfLiteStatus status = TfLiteInterpreterInvoke(interpreter);
#else
      TfLiteStatus status = interpreter->Invoke();
#endif
      dispatch_async(dispatch_get_main_queue(), ^(void){
        interpreter_busy = false;
        cb(status);
      });
    });
  } else {
#ifdef TFLITE2
    TfLiteStatus status = TfLiteInterpreterInvoke(interpreter);
#else
    TfLiteStatus status = interpreter->Invoke();
#endif
    cb(status);
  }
}

void runModelOnImage(NSDictionary* args, FlutterResult result) {
  const NSString* image_path = args[@"path"];
  const float input_mean = [args[@"imageMean"] floatValue];
  const float input_std = [args[@"imageStd"] floatValue];
  
  NSMutableArray* empty = [@[] mutableCopy];
  
  if (!interpreter || interpreter_busy) {
    NSLog(@"Failed to construct interpreter or busy.");
    return result(empty);
  }
  
  int input_size;
  feedInputTensorImage(image_path, input_mean, input_std, &input_size);
  
  runTflite(args, ^(TfLiteStatus status) {
    if (status != kTfLiteOk) {
      NSLog(@"Failed to invoke!");
      return result(empty);
    }
    
#ifdef TFLITE2
    float* output = TfLiteInterpreterGetOutputTensor(interpreter, 0)->data.f;
#else
    float* output = interpreter->typed_output_tensor<float>(0);
#endif
    if (output == NULL)
      return result(empty);
    
    const unsigned long output_size = labels.size();
    const int num_results = [args[@"numResults"] intValue];
    const float threshold = [args[@"threshold"] floatValue];
    return result(GetTopN(output, output_size, num_results, threshold));
  });
}

void feedInputTensorImage(const NSString* image_path, float input_mean, float input_std, int* input_size) {
  int image_channels;
  int image_height;
  int image_width;
  std::vector<uint8_t> image_data = LoadImageFromFile([image_path UTF8String], &image_width, &image_height, &image_channels);
  uint8_t* in = image_data.data();
  feedInputTensor(in, input_size, image_height, image_width, image_channels, input_mean, input_std);
}


void close() {
#ifdef TFLITE2
  interpreter = nullptr;
  if (delegate != nullptr)
    TFLGpuDelegateDelete(delegate);
  delegate = nullptr;
#else
  interpreter.release();
  interpreter = NULL;
#endif
  model = NULL;
  labels.clear();
}

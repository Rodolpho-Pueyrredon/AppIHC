import Cocoa
import FlutterMacOS

public class WeebiBarcodePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "weebi_barcode_scanner", binaryMessenger: registrar.messenger)
    let instance = WeebiBarcodePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
    case "isNativeLibraryAvailable":
      result(checkNativeLibraryAvailability())
    case "detectBarcode":
      handleBarcodeDetection(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func checkNativeLibraryAvailability() -> Bool {
    // Check if the native Rust library is properly loaded
    let bundle = Bundle(for: WeebiBarcodePlugin.self)
    
    let possiblePaths = [
      "Frameworks/librust_barcode_lib.dylib",
      "Frameworks/librust_barcode_lib_x86_64.dylib", 
      "Frameworks/librust_barcode_lib_aarch64.dylib"
    ]
    
    for path in possiblePaths {
      if let libraryPath = bundle.path(forResource: path, ofType: nil),
         FileManager.default.fileExists(atPath: libraryPath) {
        print("WeebiBarcodePlugin: Found native library at \(libraryPath)")
        return true
      }
    }
    
    print("WeebiBarcodePlugin: No native library found")
    return false
  }
  
  private func handleBarcodeDetection(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
          let _ = arguments["imageData"] as? FlutterStandardTypedData else {
      result(FlutterError(code: "INVALID_ARGUMENTS", 
                         message: "Missing or invalid imageData", 
                         details: nil))
      return
    }
    
    // TODO: Implement actual barcode detection using Rust FFI
    // For now, return a placeholder response
    result([
      "success": false,
      "error": "macOS barcode detection not yet implemented - Rust FFI integration needed"
    ])
  }
} 
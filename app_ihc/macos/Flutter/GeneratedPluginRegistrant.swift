//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import camera_macos
import geolocator_apple
import mobile_scanner
import sqflite_darwin
import weebi_barcode_scanner

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  CameraMacosPlugin.register(with: registry.registrar(forPlugin: "CameraMacosPlugin"))
  GeolocatorPlugin.register(with: registry.registrar(forPlugin: "GeolocatorPlugin"))
  MobileScannerPlugin.register(with: registry.registrar(forPlugin: "MobileScannerPlugin"))
  SqflitePlugin.register(with: registry.registrar(forPlugin: "SqflitePlugin"))
  WeebiBarcodePlugin.register(with: registry.registrar(forPlugin: "WeebiBarcodePlugin"))
}

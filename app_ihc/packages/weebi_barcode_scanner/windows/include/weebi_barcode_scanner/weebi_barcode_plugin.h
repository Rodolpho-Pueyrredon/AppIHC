#ifndef FLUTTER_PLUGIN_WEEBI_BARCODE_PLUGIN_H_
#define FLUTTER_PLUGIN_WEEBI_BARCODE_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

// Include the C API header
#include "weebi_barcode_plugin_c_api.h"

namespace flutter {

class WeebiBarcodePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  WeebiBarcodePlugin();

  virtual ~WeebiBarcodePlugin();

  // Disallow copy and assign.
  WeebiBarcodePlugin(const WeebiBarcodePlugin&) = delete;
  WeebiBarcodePlugin& operator=(const WeebiBarcodePlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace flutter

#endif  // FLUTTER_PLUGIN_WEEBI_BARCODE_PLUGIN_H_ 
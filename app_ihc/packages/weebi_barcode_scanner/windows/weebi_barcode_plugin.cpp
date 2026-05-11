#include "weebi_barcode_scanner/weebi_barcode_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>

namespace flutter {

// static
void WeebiBarcodePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "weebi_barcode_scanner",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<WeebiBarcodePlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

WeebiBarcodePlugin::WeebiBarcodePlugin() {}

WeebiBarcodePlugin::~WeebiBarcodePlugin() {}

void WeebiBarcodePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("getPlatformVersion") == 0) {
    std::ostringstream version_stream;
    version_stream << "Windows ";
    result->Success(flutter::EncodableValue(version_stream.str()));
  } else if (method_call.method_name().compare("isNativeLibraryAvailable") == 0) {
    // For now, return true - the actual barcode detection is handled by dart_barcode
    result->Success(flutter::EncodableValue(true));
  } else if (method_call.method_name().compare("detectBarcode") == 0) {
    // Barcode detection is handled by the dart_barcode package
    // This method exists for compatibility but shouldn't be called
    result->Success(flutter::EncodableValue(true));
  } else {
    result->NotImplemented();
  }
}

}  // namespace flutter 
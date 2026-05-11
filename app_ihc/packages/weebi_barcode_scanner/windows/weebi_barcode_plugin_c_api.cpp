#include "include/weebi_barcode_scanner/weebi_barcode_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "weebi_barcode_scanner/weebi_barcode_plugin.h"

void WeebiBarcodePluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter::WeebiBarcodePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
} 
//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <camera_windows/camera_windows.h>
#include <geolocator_windows/geolocator_windows.h>
#include <weebi_barcode_scanner/weebi_barcode_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  CameraWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("CameraWindows"));
  GeolocatorWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("GeolocatorWindows"));
  WeebiBarcodePluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("WeebiBarcodePlugin"));
}

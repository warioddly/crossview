#include "include/crossview/crossview_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "crossview_plugin.h"

void CrossviewPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  crossview::CrossviewPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

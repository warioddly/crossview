#include "include/crossview/crossview_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "crossview_plugin.h"

void CrossViewPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  crossview::CrossViewPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

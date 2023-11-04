#ifndef FLUTTER_PLUGIN_CROSSVIEW_PLUGIN_H_
#define FLUTTER_PLUGIN_CROSSVIEW_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace crossview {

class CrossviewPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  CrossviewPlugin();

  virtual ~CrossviewPlugin();

  // Disallow copy and assign.
  CrossviewPlugin(const CrossviewPlugin&) = delete;
  CrossviewPlugin& operator=(const CrossviewPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace crossview

#endif  // FLUTTER_PLUGIN_CROSSVIEW_PLUGIN_H_

#ifndef FLUTTER_PLUGIN_CROSSVIEW_PLUGIN_H_
#define FLUTTER_PLUGIN_CROSSVIEW_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace crossview {

class CrossViewPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  CrossViewPlugin();

  virtual ~CrossViewPlugin();

  // Disallow copy and assign.
  CrossViewPlugin(const CrossViewPlugin&) = delete;
  CrossViewPlugin& operator=(const CrossViewPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace crossview

#endif  // FLUTTER_PLUGIN_CROSSVIEW_PLUGIN_H_

//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <crossview/crossview_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) crossview_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "CrossviewPlugin");
  crossview_plugin_register_with_registrar(crossview_registrar);
}

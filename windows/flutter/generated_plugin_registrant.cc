//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <disks_desktop/disks_desktop_plugin.h>
#include <screen_retriever/screen_retriever_plugin.h>
#include <system_theme/system_theme_plugin.h>
#include <window_manager/window_manager_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  DisksDesktopPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("DisksDesktopPlugin"));
  ScreenRetrieverPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("ScreenRetrieverPlugin"));
  SystemThemePluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("SystemThemePlugin"));
  WindowManagerPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("WindowManagerPlugin"));
}

//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

<<<<<<< HEAD
#include <file_selector_windows/file_selector_windows.h>
=======
#include <cloud_firestore/cloud_firestore_plugin_c_api.h>
>>>>>>> 33e1a0f0d5dd2d6a9ed5300f6c526344e5ae2220
#include <firebase_auth/firebase_auth_plugin_c_api.h>
#include <firebase_core/firebase_core_plugin_c_api.h>
#include <firebase_storage/firebase_storage_plugin_c_api.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
<<<<<<< HEAD
  FileSelectorWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FileSelectorWindows"));
=======
  CloudFirestorePluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("CloudFirestorePluginCApi"));
>>>>>>> 33e1a0f0d5dd2d6a9ed5300f6c526344e5ae2220
  FirebaseAuthPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FirebaseAuthPluginCApi"));
  FirebaseCorePluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FirebaseCorePluginCApi"));
  FirebaseStoragePluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FirebaseStoragePluginCApi"));
}

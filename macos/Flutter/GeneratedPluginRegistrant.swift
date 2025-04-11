//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

<<<<<<< HEAD
import file_selector_macos
=======
import cloud_firestore
>>>>>>> 33e1a0f0d5dd2d6a9ed5300f6c526344e5ae2220
import firebase_auth
import firebase_core
import firebase_storage
import path_provider_foundation
import sqflite_darwin

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
<<<<<<< HEAD
  FileSelectorPlugin.register(with: registry.registrar(forPlugin: "FileSelectorPlugin"))
=======
  FLTFirebaseFirestorePlugin.register(with: registry.registrar(forPlugin: "FLTFirebaseFirestorePlugin"))
>>>>>>> 33e1a0f0d5dd2d6a9ed5300f6c526344e5ae2220
  FLTFirebaseAuthPlugin.register(with: registry.registrar(forPlugin: "FLTFirebaseAuthPlugin"))
  FLTFirebaseCorePlugin.register(with: registry.registrar(forPlugin: "FLTFirebaseCorePlugin"))
  FLTFirebaseStoragePlugin.register(with: registry.registrar(forPlugin: "FLTFirebaseStoragePlugin"))
  PathProviderPlugin.register(with: registry.registrar(forPlugin: "PathProviderPlugin"))
  SqflitePlugin.register(with: registry.registrar(forPlugin: "SqflitePlugin"))
}

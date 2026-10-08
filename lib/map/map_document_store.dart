import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

abstract interface class MapDocumentStore {
  Future<String?> readCurrent();

  Future<String?> readBackup();

  Future<void> writeValidated(String currentJson, String? previousJson);

  Future<String?> restoreBackup();
}

class SharedPreferencesMapDocumentStore implements MapDocumentStore {
  SharedPreferencesMapDocumentStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const currentKey = 'mushuc.map.current.v4';
  static const backupKey = 'mushuc.map.backup.v4';
  static const allowedKeys = <String>{currentKey, backupKey};

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> readCurrent() => _preferences.getString(currentKey);

  @override
  Future<String?> readBackup() => _preferences.getString(backupKey);

  @override
  Future<void> writeValidated(String currentJson, String? previousJson) async {
    final decoded = jsonDecode(currentJson);
    if (decoded is! Map || decoded['schemaVersion'] != 4) {
      throw const FormatException('Documento de mapa inválido');
    }
    if (previousJson != null) {
      final previous = jsonDecode(previousJson);
      if (previous is Map && previous['schemaVersion'] == 4) {
        await _preferences.setString(backupKey, previousJson);
      }
    }
    await _preferences.setString(currentKey, currentJson);
  }

  @override
  Future<String?> restoreBackup() async {
    final backup = await readBackup();
    if (backup != null) await _preferences.setString(currentKey, backup);
    return backup;
  }
}

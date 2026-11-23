import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/in_person_game_state.dart';

class InPersonPersistenceService {
  static const String _storageKey = 'active_in_person_game';

  static Future<void> saveActiveGame(InPersonGameState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(state.toJson());
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('Error persisting local game state: $e');
    }
  }

  static Future<InPersonGameState?> loadActiveGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString == null || jsonString.isEmpty) return null;

      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return InPersonGameState.fromJson(jsonMap);
    } catch (e) {
      debugPrint('Error loading persisted local game state: $e');
      return null;
    }
  }

  static Future<void> clearActiveGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      debugPrint('Error clearing local game state: $e');
    }
  }
}

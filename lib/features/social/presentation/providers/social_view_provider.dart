// Created by Hamza Ali on 2026-11-25.
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/repositories/social_repository.dart';
import 'social_providers.dart';

class SocialViewState {
  const SocialViewState(
      {this.tab = 1,
      this.query = '',
      this.searching = false,
      this.results = const [],
      this.error,
      this.sent = const {}});
  final int tab;
  final String query;
  final bool searching;
  final List<UserEntity> results;
  final String? error;
  final Set<String> sent;
  SocialViewState copyWith(
          {int? tab,
          String? query,
          bool? searching,
          List<UserEntity>? results,
          String? error,
          Set<String>? sent}) =>
      SocialViewState(
          tab: tab ?? this.tab,
          query: query ?? this.query,
          searching: searching ?? this.searching,
          results: results ?? this.results,
          error: error,
          sent: sent ?? this.sent);
}

class SocialViewController extends StateNotifier<SocialViewState> {
  SocialViewController(this.repository) : super(const SocialViewState());
  final SocialRepository repository;
  Timer? _debounce;
  int _generation = 0;
  void selectTab(int tab) => state = state.copyWith(tab: tab);
  void markSent(String uid) =>
      state = state.copyWith(sent: {...state.sent, uid});
  void search(String query) {
    _debounce?.cancel();
    final generation = ++_generation;
    state = state.copyWith(
        query: query, searching: query.trim().isNotEmpty, results: []);
    if (query.trim().isEmpty) return;
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final results = await repository.searchUsers(query.trim());
        if (mounted && generation == _generation)
          state = state.copyWith(searching: false, results: results);
      } catch (_) {
        if (mounted && generation == _generation)
          state = state.copyWith(
              searching: false,
              error: 'Couldn’t search agents. Please try again.');
      }
    });
  }

  @override
  void dispose() {
    _generation++;
    _debounce?.cancel();
    super.dispose();
  }
}

final socialViewProvider =
    StateNotifierProvider.autoDispose<SocialViewController, SocialViewState>(
        (ref) => SocialViewController(ref.watch(socialRepositoryProvider)));

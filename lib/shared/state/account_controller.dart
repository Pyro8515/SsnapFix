import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/account_repository.dart';
import '../data/api_client.dart';
import '../data/models/account_profile.dart';
import '../extensions/string_extensions.dart';

const _lastRoleKey = 'getdone_last_role';
const _onlineStatusKey = 'getdone_online_status';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(ref.watch(apiClientProvider)),
);

final accountControllerProvider =
    StateNotifierProvider<AccountController, AccountState>((ref) {
  final repository = ref.watch(accountRepositoryProvider);
  return AccountController(repository);
});

class AccountController extends StateNotifier<AccountState> {
  AccountController(this._repository)
      : _prefsFuture = SharedPreferences.getInstance(),
        super(AccountState.initial()) {
    _restoreOnlineStatus();
    Future<void>.microtask(loadProfile);
  }

  final AccountRepository _repository;
  final Future<SharedPreferences> _prefsFuture;

  Future<void> loadProfile() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      state = AccountState.initial();
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final profile = await _repository.fetchProfile();
      final prefs = await _prefsFuture;
      final storedRoleName = prefs.getString(_lastRoleKey);
      AccountProfile adjustedProfile = profile;
      if (storedRoleName != null) {
        final storedRole = storedRoleName.toAccountRole();
        if (profile.isVerificationApproved || storedRole == AccountRole.customer) {
          adjustedProfile = adjustedProfile.copyWith(activeRole: storedRole);
        }
      }

      if (!adjustedProfile.isVerificationApproved &&
          adjustedProfile.activeRole == AccountRole.professional) {
        adjustedProfile = adjustedProfile.copyWith(activeRole: AccountRole.customer);
      }

      await prefs.setString(_lastRoleKey, adjustedProfile.activeRole.name);

      state = state.copyWith(
        isLoading: false,
        profile: adjustedProfile,
        shouldPromptVerification: adjustedProfile.activeRole == AccountRole.professional &&
            !adjustedProfile.isVerificationApproved,
      );
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        state = AccountState.initial();
      } else {
        state = state.copyWith(isLoading: false, errorMessage: error.message);
      }
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  Future<bool> switchRole(AccountRole role) async {
    final profile = state.profile;
    if (profile == null) {
      return false;
    }
    if (profile.activeRole == role) {
      return true;
    }
    if (role == AccountRole.professional && !profile.isVerificationApproved) {
      state = state.copyWith(shouldPromptVerification: true);
      return false;
    }

    state = state.copyWith(isSwitchingRole: true, errorMessage: null);
    try {
      final newRole = await _repository.switchRole(role);
      final updatedProfile = profile.copyWith(activeRole: newRole);
      final prefs = await _prefsFuture;
      await prefs.setString(_lastRoleKey, newRole.name);
      state = state.copyWith(
        isSwitchingRole: false,
        profile: updatedProfile,
        shouldPromptVerification: newRole == AccountRole.professional &&
            !updatedProfile.isVerificationApproved,
      );
      return true;
    } on ApiException catch (error) {
      state = state.copyWith(isSwitchingRole: false, errorMessage: error.message);
      return false;
    } catch (error) {
      state = state.copyWith(isSwitchingRole: false, errorMessage: error.toString());
      return false;
    }
  }

  void acknowledgeVerificationPrompt() {
    if (state.shouldPromptVerification) {
      state = state.copyWith(shouldPromptVerification: false);
    }
  }

  Future<void> updateOnlineStatus(bool value) async {
    state = state.copyWith(isOnline: value);
    final prefs = await _prefsFuture;
    await prefs.setBool(_onlineStatusKey, value);
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await Supabase.instance.client.auth.signOut();
      final prefs = await _prefsFuture;
      await prefs.remove(_lastRoleKey);
      state = AccountState.initial();
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }

  Future<void> _restoreOnlineStatus() async {
    final prefs = await _prefsFuture;
    final saved = prefs.getBool(_onlineStatusKey) ?? false;
    state = state.copyWith(isOnline: saved);
  }
}

class AccountState {
  const AccountState({
    required this.isLoading,
    required this.isSwitchingRole,
    required this.isOnline,
    required this.profile,
    required this.errorMessage,
    required this.shouldPromptVerification,
  });

  final bool isLoading;
  final bool isSwitchingRole;
  final bool isOnline;
  final AccountProfile? profile;
  final String? errorMessage;
  final bool shouldPromptVerification;

  factory AccountState.initial() {
    return const AccountState(
      isLoading: false,
      isSwitchingRole: false,
      isOnline: false,
      profile: null,
      errorMessage: null,
      shouldPromptVerification: false,
    );
  }

  AccountState copyWith({
    bool? isLoading,
    bool? isSwitchingRole,
    bool? isOnline,
    AccountProfile? profile,
    Object? errorMessage = _sentinel,
    bool? shouldPromptVerification,
  }) {
    return AccountState(
      isLoading: isLoading ?? this.isLoading,
      isSwitchingRole: isSwitchingRole ?? this.isSwitchingRole,
      isOnline: isOnline ?? this.isOnline,
      profile: profile ?? this.profile,
      errorMessage:
          identical(errorMessage, _sentinel) ? this.errorMessage : errorMessage as String?,
      shouldPromptVerification:
          shouldPromptVerification ?? this.shouldPromptVerification,
    );
  }
}

const _sentinel = Object();

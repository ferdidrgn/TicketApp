import 'package:flutter/foundation.dart';
import 'package:ticketapp/core/common/base_state.dart';

@immutable
class AppToolsState extends BaseState {
  final String? privacyPolicy;
  final String? termsCondition;
  final DateTime? lastUpdated;

  const AppToolsState({
    this.privacyPolicy,
    this.termsCondition,
    this.lastUpdated,
    super.isLoading = false,
    super.errorMessage,
  });

  @override
  AppToolsState copyWith({
    final String? privacyPolicy,
    final String? termsCondition,
    final DateTime? lastUpdated,
    final bool? isLoading,
    final String? errorMessage,
  }) =>
      AppToolsState(
        privacyPolicy: privacyPolicy ?? this.privacyPolicy,
        termsCondition: termsCondition ?? this.termsCondition,
        lastUpdated: lastUpdated ?? this.lastUpdated,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

import '../../../core/common/base_state.dart';

abstract class LoadableState<T> extends BaseState {
  final T? data;

  const LoadableState({
    super.isLoading = false,
    super.errorMessage,
    this.data,
  });

  bool get hasError => (errorMessage != null && errorMessage!.isNotEmpty);
  bool get isEmpty => data == null || (data != null && data is List && (data as List).isEmpty);
}

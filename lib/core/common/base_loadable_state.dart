import 'base_state.dart';

abstract class LoadableState<T, R> extends BaseState {
  final T? dataSingle;
  final R? dataList;

  const LoadableState({
    super.isLoading = false,
    super.errorMessage,
    this.dataSingle,
    this.dataList,
  });

  bool get hasError => (errorMessage != null && errorMessage!.isNotEmpty);
  bool get isSingleNull => dataSingle == null;
  bool get isListEmpty => dataList == null || (dataList != null && (dataList as List).isEmpty);
}

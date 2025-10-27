import 'base_state.dart';

/// Tekil ve liste verisi tutabilen generic state sınıfı
abstract class LoadableState<T, R> extends BaseState {
  final T? dataSingle;
  final R? dataList;

  const LoadableState({
    this.dataSingle,
    this.dataList,
    super.isLoading = false,
    super.errorMessage,
  });

  @override
  LoadableState<T, R> copyWith({
    final bool? isLoading,
    final String? errorMessage,
    final T? dataSingle,
    final R? dataList,
  });

  bool get hasError => (errorMessage != null && errorMessage!.isNotEmpty);

  bool get isSingleNull => dataSingle == null;
  bool get hasDataSingle => dataSingle != null;

  bool get hasData => !isListNullOrEmpty;
  bool get isListNullOrEmpty => dataList == null || ((dataList != null) as List).isEmpty;

  int get dataListCount => ((dataList != null) as List).length;

}

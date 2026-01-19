import 'base_state.dart';

/// Tekil veya liste veri tutabilen generic state yapısı
abstract class LoadableState<T, R extends List> extends BaseState {
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

  bool get hasError => (errorMessage?.isNotEmpty ?? false);
  bool get isSingleNull => dataSingle == null;
  bool get hasDataSingle => dataSingle != null;

  bool get isListNullOrEmpty => dataList == null || dataList!.isEmpty;
  bool get hasData => !isListNullOrEmpty;

  int get dataListLength => dataList?.length ?? 0;
}

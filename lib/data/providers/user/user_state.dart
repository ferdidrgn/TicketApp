import '../../../core/common/base_loadable_state.dart';
import '../../../domain/entities/user.dart';

class UserState extends LoadableState<User, List<User>> {
  const UserState({
    super.dataList,
    super.dataSingle,
    super.isLoading = false,
    super.errorMessage,
  });

  @override
  UserState copyWith({
    final User? dataSingle,
    final List<User>? dataList,
    final bool? isLoading,
    final String? errorMessage,
  }) =>
      UserState(
        dataSingle: dataSingle ?? this.dataSingle,
        dataList: dataList ?? this.dataList,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
      );
}

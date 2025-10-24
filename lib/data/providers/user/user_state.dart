import '../../../core/common/base_loadable_state.dart';
import '../../../domain/entities/user.dart';

class UserState extends LoadableState<User, List<User>> {
  const UserState({
    super.isLoading = false,
    super.errorMessage,
    final User? user,
    final List<User>? users,
  }) : super(dataSingle: user, dataList: users);

  @override
  UserState copyWith({
    final User? dataSingle,
    final List<User>? dataList,
    final bool? isLoading,
    final String? errorMessage,
  }) =>
      UserState(
        user: dataSingle ?? this.dataSingle,
        users: dataList ?? this.dataList,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
      );
}

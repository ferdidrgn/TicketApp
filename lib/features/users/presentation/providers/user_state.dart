import '../../../../core/base/base_state.dart';
import '../../domain/entities/user.dart';

class UserState extends BaseState {
  final User? dataSingle;

  const UserState(
      {this.dataSingle, super.isLoading = false, super.errorMessage});

  @override
  UserState copyWith({
    final User? dataSingle,
    final List<User>? dataList,
    final bool? isLoading,
    final String? errorMessage,
  }) =>
      UserState(
        dataSingle: dataSingle ?? this.dataSingle,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  String get userFullName {
    final user = dataSingle;
    if (user == null) return 'Kullanıcı';

    if (user.firstName.isNotEmpty && user.lastName.isNotEmpty)
      return '${user.firstName} ${user.lastName}';
    else if (user.firstName.isNotEmpty)
      return user.firstName;
    else if (user.lastName.isNotEmpty)
      return user.lastName;
    else
      return 'Kullanıcı';
  }
}

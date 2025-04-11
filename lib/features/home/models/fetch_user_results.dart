import 'package:lokconnect/features/home/models/user_model.dart';

class FetchUsersResult {
  final List<UserModel> users;
  final bool hasMore;

  FetchUsersResult({required this.users, required this.hasMore});
}
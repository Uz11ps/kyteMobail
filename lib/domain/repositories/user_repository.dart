import '../../data/models/user_model.dart';

abstract class UserRepository {
  Future<UserModel> getCurrentUser();
  Future<UserModel> updateProfile({
    String? name,
    String? nickname,
    String? phone,
    String? email,
    String? about,
    DateTime? birthday,
  });
  Future<String> uploadAvatar(String filePath);
}




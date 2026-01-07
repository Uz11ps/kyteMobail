import '../../data/models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> login(String email, String password);
  Future<UserModel> loginWithPhone(String phone, String code);
  Future<UserModel> register(String email, String password, {String? name});
  Future<UserModel> registerWithPhone(String phone, String code, {String? name});
  Future<void> sendPhoneVerificationCode(String phone);
  Future<void> sendEmailVerificationCode(String email);
  Future<UserModel> loginWithEmailCode(String email, String code, {String? name});
  Future<UserModel> loginWithGoogle(String idToken, String accessToken, String email, String name, {String? picture, String? googleId});
  Future<UserModel> loginAsGuest();
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  Future<bool> isAuthenticated();
}


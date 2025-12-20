part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String? name;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    this.name,
  });

  @override
  List<Object> get props => [email, password, name ?? ''];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthGoogleLoginRequested extends AuthEvent {
  final String idToken;
  final String accessToken;
  final String email;
  final String name;
  final String? picture;
  final String? googleId;

  const AuthGoogleLoginRequested({
    required this.idToken,
    required this.accessToken,
    required this.email,
    required this.name,
    this.picture,
    this.googleId,
  });

  @override
  List<Object> get props => [idToken, accessToken, email, name, picture ?? '', googleId ?? ''];
}

class AuthPhoneCodeSendRequested extends AuthEvent {
  final String phone;

  const AuthPhoneCodeSendRequested({required this.phone});

  @override
  List<Object> get props => [phone];
}

class AuthPhoneRegisterRequested extends AuthEvent {
  final String phone;
  final String code;
  final String? name;

  const AuthPhoneRegisterRequested({
    required this.phone,
    required this.code,
    this.name,
  });

  @override
  List<Object> get props => [phone, code, name ?? ''];
}

class AuthPhoneLoginRequested extends AuthEvent {
  final String phone;
  final String code;

  const AuthPhoneLoginRequested({
    required this.phone,
    required this.code,
  });

  @override
  List<Object> get props => [phone, code];
}


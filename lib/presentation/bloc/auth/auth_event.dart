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


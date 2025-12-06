part of 'google_bloc.dart';

abstract class GoogleState extends Equatable {
  const GoogleState();

  @override
  List<Object> get props => [];
}

class GoogleInitial extends GoogleState {}

class GoogleLoading extends GoogleState {}

class GoogleSignInSuccess extends GoogleState {
  final String token;

  const GoogleSignInSuccess({required this.token});

  @override
  List<Object> get props => [token];
}

class GoogleSignInCancelled extends GoogleState {}

class GoogleTokenSubmittedSuccess extends GoogleState {}

class GoogleMeetCreated extends GoogleState {
  final String meetUrl;

  const GoogleMeetCreated({required this.meetUrl});

  @override
  List<Object> get props => [meetUrl];
}

class GoogleError extends GoogleState {
  final String message;

  const GoogleError({required this.message});

  @override
  List<Object> get props => [message];
}


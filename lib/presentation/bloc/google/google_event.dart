part of 'google_bloc.dart';

abstract class GoogleEvent extends Equatable {
  const GoogleEvent();

  @override
  List<Object> get props => [];
}

class GoogleSignInRequested extends GoogleEvent {}

class GoogleTokenSubmitted extends GoogleEvent {
  final String token;

  const GoogleTokenSubmitted({required this.token});

  @override
  List<Object> get props => [token];
}

class GoogleMeetCreateRequested extends GoogleEvent {}


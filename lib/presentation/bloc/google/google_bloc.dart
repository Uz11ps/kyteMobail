import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../domain/repositories/google_repository.dart';

part 'google_event.dart';
part 'google_state.dart';

class GoogleBloc extends Bloc<GoogleEvent, GoogleState> {
  final GoogleRepository googleRepository;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'https://www.googleapis.com/auth/gmail.readonly'],
  );

  GoogleBloc({required this.googleRepository}) : super(GoogleInitial()) {
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<GoogleTokenSubmitted>(_onGoogleTokenSubmitted);
    on<GoogleMeetCreateRequested>(_onGoogleMeetCreateRequested);
  }

  Future<void> _onGoogleSignInRequested(
    GoogleSignInRequested event,
    Emitter<GoogleState> emit,
  ) async {
    emit(GoogleLoading());
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        emit(GoogleSignInCancelled());
        return;
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      final String? accessToken = auth.accessToken;

      if (accessToken != null) {
        await googleRepository.submitGmailToken(accessToken);
        emit(GoogleSignInSuccess(token: accessToken));
      } else {
        emit(const GoogleError(message: 'Не удалось получить токен'));
      }
    } catch (e) {
      String errorMessage = 'Неизвестная ошибка';
      try {
        if (e != null) {
          errorMessage = e.toString();
        }
      } catch (_) {
        errorMessage = 'Ошибка Google Sign In';
      }
      emit(GoogleError(message: errorMessage));
    }
  }

  Future<void> _onGoogleTokenSubmitted(
    GoogleTokenSubmitted event,
    Emitter<GoogleState> emit,
  ) async {
    emit(GoogleLoading());
    try {
      await googleRepository.submitGmailToken(event.token);
      emit(GoogleTokenSubmittedSuccess());
    } catch (e) {
      String errorMessage = 'Неизвестная ошибка';
      try {
        if (e != null) {
          errorMessage = e.toString();
        }
      } catch (_) {
        errorMessage = 'Ошибка отправки токена';
      }
      emit(GoogleError(message: errorMessage));
    }
  }

  Future<void> _onGoogleMeetCreateRequested(
    GoogleMeetCreateRequested event,
    Emitter<GoogleState> emit,
  ) async {
    emit(GoogleLoading());
    try {
      final meetUrl = await googleRepository.createGoogleMeet();
      emit(GoogleMeetCreated(meetUrl: meetUrl));
    } catch (e) {
      String errorMessage = 'Неизвестная ошибка';
      try {
        if (e != null) {
          errorMessage = e.toString();
        }
      } catch (_) {
        errorMessage = 'Ошибка создания Google Meet';
      }
      emit(GoogleError(message: errorMessage));
    }
  }
}


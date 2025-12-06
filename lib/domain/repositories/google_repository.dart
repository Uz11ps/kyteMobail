abstract class GoogleRepository {
  Future<void> submitGmailToken(String token);
  Future<String?> getGmailToken();
  Future<String> createGoogleMeet();
}


import 'package:flutter_session_manager/flutter_session_manager.dart';

class SessionData {
  static SessionManager? session;
  static Future<void> initialize() async {
    session = SessionManager();
  }
}

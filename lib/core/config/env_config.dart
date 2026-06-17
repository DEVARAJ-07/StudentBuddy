import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get openRouterKey => dotenv.get('OPENROUTER_KEY');
}

import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  Env();

  @EnviedField(varName: 'GOOGLE_CLIENT_KEY', obfuscate: true)
  static final String googleClientKey = _Env.googleClientKey;
  @EnviedField(varName: 'GOOGLE_SECRET_KEY', obfuscate: true)
  static final String googleSecretKey = _Env.googleSecretKey;
}
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prep404/core/config/app_config.dart';

void main() {
  test('default callback matches configured app redirect URI', () {
    expect(
      AppConfig.authRedirectUri,
      'com.rxxxeron.prep404://login-callback',
    );
  });

  test('AppConfig loads dynamically from dotenv when initialized', () async {
    await dotenv.load(
      fileName: 'test.env',
      isOptional: true,
      mergeWith: const {
        'SUPABASE_URL': 'https://test-project.supabase.co',
        'SUPABASE_ANON_KEY': 'test-anon-key-12345',
        'API_HOST': 'http://192.168.1.100:4040',
        'AUTH_REDIRECT_URI': 'custom.scheme://callback',
        'GOOGLE_CLIENT_ID': 'test-client-id.apps.googleusercontent.com',
        'GOOGLE_WEB_CLIENT_ID': 'test-client-id.apps.googleusercontent.com',
      },
    );

    expect(AppConfig.supabaseUrl, 'https://test-project.supabase.co');
    expect(AppConfig.supabaseAnonKey, 'test-anon-key-12345');
    expect(AppConfig.apiHost, 'http://192.168.1.100:4040');
    expect(AppConfig.authRedirectUri, 'custom.scheme://callback');
    expect(AppConfig.googleClientId,
        'test-client-id.apps.googleusercontent.com');
    expect(AppConfig.googleWebClientId,
        'test-client-id.apps.googleusercontent.com');
  });
}

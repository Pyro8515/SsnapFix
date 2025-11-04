import '../extensions/string_extensions.dart';
import 'api_client.dart';
import 'models/account_profile.dart';

class AccountRepository {
  AccountRepository(this._client);

  final ApiClient _client;

  Future<AccountProfile> fetchProfile() async {
    final response = await _client.get('/api/me');
    return AccountProfile.fromJson(response);
  }

  Future<AccountRole> switchRole(AccountRole role) async {
    final response = await _client.post(
      '/api/role/switch',
      body: <String, dynamic>{'active_role': role.name},
    );
    return (response['active_role'] as String?)?.toAccountRole() ?? role;
  }
}

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/errors/failures.dart';
import '../models/user_credentials_model.dart';

abstract class IptvLocalDataSource {
  Future<void> saveCredentials(UserCredentialsModel credentials);
  Future<UserCredentialsModel?> getCredentials();
  Future<void> clearCredentials();
}

class IptvLocalDataSourceImpl implements IptvLocalDataSource {
  final FlutterSecureStorage secureStorage;

  IptvLocalDataSourceImpl(this.secureStorage);

  @override
  Future<void> saveCredentials(UserCredentialsModel credentials) async {
    try {
      await secureStorage.write(
        key: StorageKeys.userInfo,
        value: jsonEncode(credentials.toJson()),
      );
    } catch (e) {
      throw CacheException('فشل حفظ البيانات');
    }
  }

  @override
  Future<UserCredentialsModel?> getCredentials() async {
    try {
      final data = await secureStorage.read(key: StorageKeys.userInfo);
      if (data == null) return null;
      final json = jsonDecode(data) as Map<String, dynamic>;
      return UserCredentialsModel(
        serverUrl: json['server_url'] as String,
        username: json['username'] as String,
        password: json['password'] as String,
        status: json['status'] as String?,
        expDate: json['exp_date'] as String?,
        maxConnections: json['max_connections'] as int?,
        activeConnections: json['active_connections'] as int?,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> clearCredentials() async {
    await secureStorage.delete(key: StorageKeys.userInfo);
  }
}

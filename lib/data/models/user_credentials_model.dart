import '../../domain/entities/user_credentials.dart';

class UserCredentialsModel extends UserCredentials {
  const UserCredentialsModel({
    required super.serverUrl,
    required super.username,
    required super.password,
    super.status,
    super.expDate,
    super.maxConnections,
    super.activeConnections,
  });

  factory UserCredentialsModel.fromJson({
    required String serverUrl,
    required String username,
    required String password,
    required Map<String, dynamic> json,
  }) {
    final userInfo = json['user_info'] as Map<String, dynamic>? ?? {};
    return UserCredentialsModel(
      serverUrl: serverUrl,
      username: username,
      password: password,
      status: userInfo['status']?.toString(),
      expDate: userInfo['exp_date']?.toString(),
      maxConnections: int.tryParse(userInfo['max_connections']?.toString() ?? ''),
      activeConnections: int.tryParse(userInfo['active_cons']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'server_url': serverUrl,
    'username': username,
    'password': password,
    'status': status,
    'exp_date': expDate,
    'max_connections': maxConnections,
    'active_connections': activeConnections,
  };
}

import 'package:equatable/equatable.dart';

class UserCredentials extends Equatable {
  final String serverUrl;
  final String username;
  final String password;
  final String? status;
  final String? expDate;
  final int? maxConnections;
  final int? activeConnections;

  const UserCredentials({
    required this.serverUrl,
    required this.username,
    required this.password,
    this.status,
    this.expDate,
    this.maxConnections,
    this.activeConnections,
  });

  @override
  List<Object?> get props => [serverUrl, username, password, status, expDate];
}

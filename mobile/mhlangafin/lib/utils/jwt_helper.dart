import 'dart:convert';

class JwtHelper {
  static Map<String, dynamic> decode(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid token');
    }

    final payload = _decodeBase64(parts[1]);
    final payloadMap = json.decode(payload);
    if (payloadMap is! Map<String, dynamic>) {
      throw Exception('Invalid payload');
    }

    return payloadMap;
  }

  static String _decodeBase64(String str) {
    String output = str.replaceAll('-', '+').replaceAll('_', '/');

    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        throw Exception('Illegal base64url string!"');
    }

    return utf8.decode(base64Url.decode(output));
  }

  static int getUserId(String token) {
    final payload = decode(token);
    final userId = payload['nameid'] ?? 
                 payload['sub'] ?? 
                 payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'];
    return int.parse(userId.toString());
  }

  static String getUserName(String token) {
    final payload = decode(token);
    return payload['unique_name'] ?? 
           payload['name'] ?? 
           payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name'] ?? 
           payload['sub'] ?? 
           'MEMBER';
  }
}

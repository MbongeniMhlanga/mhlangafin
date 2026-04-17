import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5075/api'; // Android emulator localhost
  
  // Authentication endpoints
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      if (errorBody['errors'] != null) {
        final errors = errorBody['errors'];
        if (errors['Email'] != null && errors['Email'].isNotEmpty) {
          throw Exception(errors['Email'][0]);
        }
        if (errors['Password'] != null && errors['Password'].isNotEmpty) {
          throw Exception(errors['Password'][0]);
        }
      }
      if (errorBody['message'] != null) {
        throw Exception(errorBody['message']);
      }
      throw Exception('Login failed: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> register(String email, String password, String firstName, String lastName) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      if (errorBody['errors'] != null) {
        final errors = errorBody['errors'];
        if (errors['Email'] != null && errors['Email'].isNotEmpty) {
          throw Exception(errors['Email'][0]);
        }
        if (errors['Password'] != null && errors['Password'].isNotEmpty) {
          throw Exception(errors['Password'][0]);
        }
        if (errors['FirstName'] != null && errors['FirstName'].isNotEmpty) {
          throw Exception(errors['FirstName'][0]);
        }
        if (errors['LastName'] != null && errors['LastName'].isNotEmpty) {
          throw Exception(errors['LastName'][0]);
        }
      }
      if (errorBody['message'] != null) {
        throw Exception(errorBody['message']);
      }
      throw Exception('Registration failed: ${response.statusCode}');
    }
  }

  // Account endpoints
  Future<List<dynamic>> getAccounts(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/accounts/my'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load accounts: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> createAccount(String token, int userId, String accountName, double initialBalance) async {
    final response = await http.post(
      Uri.parse('$baseUrl/accounts'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'userId': userId,
        'accountName': accountName,
        'initialBalance': initialBalance,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create account: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> internalTransfer(String token, int fromAccountId, int toAccountId, double amount) async {
    final response = await http.post(
      Uri.parse('$baseUrl/accounts/internal-transfer'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fromAccountId': fromAccountId,
        'toAccountId': toAccountId,
        'amount': amount,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Transfer failed: ${response.statusCode}');
    }
  }

  // Beneficiary endpoints
  Future<List<dynamic>> getBeneficiaries(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/beneficiaries'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load beneficiaries: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> addBeneficiary(String token, String name, String accountNumber, String? bankName) async {
    final response = await http.post(
      Uri.parse('$baseUrl/beneficiaries'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'accountNumber': accountNumber,
        'bankName': bankName,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add beneficiary: ${response.statusCode}');
    }
  }

  // Transaction endpoints
  Future<Map<String, dynamic>> getTransactionHistory(String token, String accountNumber, int page, int pageSize) async {
    final response = await http.get(
      Uri.parse('$baseUrl/transactions/history?accountNumber=$accountNumber&page=$page&pageSize=$pageSize'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load transaction history: ${response.statusCode}');
    }
  }

  Future<Uint8List> downloadStatement(String token, String accountNumber, DateTime startDate, DateTime endDate, String format) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transactions/statement/download?format=$format'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'accountNumber': accountNumber,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to download statement: ${response.statusCode}');
    }
  }

  // Transfer endpoints
  Future<Map<String, dynamic>> makeTransfer(String token, String fromAccountNumber, String toAccountNumber, double amount, String benRef, String senderRef) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transactions/transfer'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fromAccountNumber': fromAccountNumber,
        'toAccountNumber': toAccountNumber,
        'amount': amount,
        'beneficiaryReference': benRef,
        'senderReference': senderRef,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Transfer failed: ${response.statusCode}');
    }
  }

  // Admin endpoints
  Future<Map<String, dynamic>> getAdminStats(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/stats'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load admin stats: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> getAdminUsers(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/users'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load users: ${response.statusCode}');
    }
  }

  Future<void> updateUserStatus(String token, int userId, String status) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/admin/users/$userId/status'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'status': status,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update user status: ${response.statusCode}');
    }
  }

  Future<void> resetUserPassword(String token, int userId, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/users/$userId/reset-password'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to reset password: ${response.statusCode}');
    }
  }

  Future<dynamic> getAdminTransactions(String token, int page, int pageSize, String statusFilter) async {
    final effectiveStatus = statusFilter == 'All' ? '' : statusFilter;
    final response = await http.get(
      Uri.parse('$baseUrl/admin/transactions?status=$effectiveStatus&page=$page&pageSize=$pageSize'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load transactions: ${response.statusCode}');
    }
  }

  Future<void> approveTransaction(String token, int transactionId, {String? note}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/transactions/$transactionId/approve'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'note': note,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to approve transaction: ${response.statusCode}');
    }
  }

  Future<void> rejectTransaction(String token, int transactionId, {String? note}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/transactions/$transactionId/reject'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'note': note,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to reject transaction: ${response.statusCode}');
    }
  }

  Future<void> updateAccountStatus(String token, int accountId, String status) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/admin/accounts/$accountId/status'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'status': status,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update account status: ${response.statusCode}');
    }
  }
}

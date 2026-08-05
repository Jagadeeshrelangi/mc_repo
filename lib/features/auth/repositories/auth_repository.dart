class AuthRepository {
  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  Future<bool> forgotPassword(String email) async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  Future<bool> register(String name, String email, String phone, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }
}

/// Development-only mock repository.
///
/// This is the frozen repository seam: it simulates backend latency and
/// always returns `true` so the full auth flow is exercisable without a
/// backend. It performs NO credential verification and MUST be replaced by
/// a real HTTP repository (backend auth) before any production deployment.
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

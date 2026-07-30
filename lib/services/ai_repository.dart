import 'api_client.dart';

class AIRepository {
  final ApiClient _apiClient = ApiClient();

  static final AIRepository _instance = AIRepository._internal();
  factory AIRepository() => _instance;
  AIRepository._internal();

  /// Create a new unique chat session
  Future<String> createSession() async {
    try {
      final response = await _apiClient.post("/conversation/session", {});
      return response['session_id'] as String;
    } catch (e) {
      rethrow;
    }
  }

  /// Sends a message inside the conversational orchestrator
  Future<Map<String, dynamic>> sendChatMessage(String message, String sessionId) async {
    try {
      final body = {
        "message": message,
        "session_id": sessionId,
      };
      return await _apiClient.post("/conversation/chat", body);
    } catch (e) {
      rethrow;
    }
  }

  /// Retrieves the history matching the session key
  Future<List<Map<String, dynamic>>> getHistory(String sessionId) async {
    try {
      final response = await _apiClient.get(
        "/conversation/history",
        queryParameters: {"session_id": sessionId},
      );
      final rawList = response['history'] as List<dynamic>;
      return rawList.map((item) => {
        "role": item['role'] as String,
        "content": item['content'] as String,
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Explicitly triggers the diagnostic engine
  Future<Map<String, dynamic>> diagnoseVehicle({
    required String vehicleType,
    required List<String> symptoms,
    required int mileage,
    String? obdCode,
  }) async {
    try {
      final body = {
        "vehicle_type": vehicleType,
        "symptoms": symptoms,
        "mileage": mileage,
        "obd_error_code": obdCode ?? "None",
      };
      return await _apiClient.post("/diagnosis/diagnose", body);
    } catch (e) {
      rethrow;
    }
  }

  /// Query the knowledge base directly via RAG search
  Future<Map<String, dynamic>> queryKnowledgeBase(String query, {int k = 2}) async {
    try {
      final body = {
        "query": query,
        "k": k,
      };
      return await _apiClient.post("/knowledge/query", body);
    } catch (e) {
      rethrow;
    }
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mecha_connect/services/ai_repository.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  test('End-to-End Chat, Session, History, and Diagnosis Integration Check', () async {
    // Manually load the environment configuration mock for test environment context
    dotenv.testLoad(fileInput: 'BACKEND_URL=http://127.0.0.1:8000/api/v1');
    
    print("\n--- 1. Initializing AIRepository ---");
    final repo = AIRepository();
    
    print("--- 2. Testing Session Creation API (/conversation/session) ---");
    final sessionId = await repo.createSession();
    print("SUCCESS: Session created: $sessionId");
    expect(sessionId, startsWith("session_"));
    
    print("--- 3. Testing Chat Conversation API (/conversation/chat) ---");
    final chatRes = await repo.sendChatMessage(
      "Help, my bike won't start and makes a clicking sound.",
      sessionId,
    );
    print("Chat Intent: ${chatRes['intent']}");
    print("Chat Reply:  ${chatRes['response']}");
    expect(chatRes['intent'], equals("Vehicle Diagnosis"));
    expect(chatRes['diagnostic_details'], isNotNull);
    expect(chatRes['diagnostic_details']['predicted_fault'], equals("Alternator or Battery Failure"));
    
    print("--- 4. Testing History Retrieval API (/conversation/history) ---");
    final history = await repo.getHistory(sessionId);
    print("History Entries: ${history.length}");
    expect(history.length, equals(2)); // User message + assistant reply
    expect(history[0]['role'], equals("user"));
    
    print("--- 5. Testing Diagnosis Engine API (/diagnosis/diagnose) ---");
    final diag = await repo.diagnoseVehicle(
      vehicleType: "Car",
      symptoms: ["Brake noise", "Check engine light"],
      mileage: 60000,
    );
    print("Predicted Fault: ${diag['predicted_fault']}");
    print("Estimated Cost:  INR ${diag['estimated_cost']}");
    expect(diag['predicted_fault'], equals("Brake Pad Wear / Brake Fault"));
    expect(diag['estimated_cost'], equals(1500));
    
    print("--- ALL E2E VERIFICATIONS PASSED ---");
  });
}

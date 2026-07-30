# Mecha Connect Local Installation Guide

Follow these steps to set up both the backend services and the Flutter mobile client in your local development environment.

---

## Prerequisites

Ensure you have the following software installed:
* **Python** ($\ge 3.10$)
* **Flutter SDK** ($\ge 3.19$)
* **Git**
* An active **Google Gemini API Key** (to enable RAG and chat features).

---

## 1. Backend Environment Setup

### A. Clone and Navigate
Open your terminal and clone the repository, then navigate to the backend directory:
```bash
cd mecha_connect/backend
```

### B. Virtual Environment
Create and activate a Python virtual environment:
```bash
# Windows
python -m venv venv
.\venv\Scripts\activate

# macOS / Linux
python3 -m venv venv
source venv/bin/activate
```

### C. Install Dependencies
Install all required libraries:
```bash
pip install -r requirements.txt
```

### D. Environment Variables Configuration
Create a `.env` file in the root of the `backend/` directory, using the provided `.env.example` as a template:
```env
GEMINI_API_KEY=your_gemini_api_key_here
DATABASE_URL=sqlite+aiosqlite:///./mecha.db
LOG_LEVEL=INFO
```

---

## 2. ML Training & Index Generation

Before running the API server, you must generate the telemetry dataset, train the fault classification model, and compile the RAG vector index.

### A. Telemetry Generation and ML Training
Run the data generator and the model training pipeline:
```bash
python ai/data/generate_data.py
python ai/models/train.py
```
This saves the best-performing model to `ai/models/fault_classifier.joblib`.

### B. RAG Index Compilation
Compile the FAISS vector store index:
```bash
python ai/build_rag_index.py
```
This chunks the manual text files and saves the index files under `ai/knowledge_base/faiss_index/`.

---

## 3. Run the Backend API

Start the FastAPI application using the Uvicorn server:
```bash
uvicorn app.main:app --reload
```
The server will start at `http://127.0.0.1:8000`. You can inspect the interactive OpenAPI/Swagger dashboard at `http://127.0.0.1:8000/docs`.

---

## 4. Flutter Client Setup

Open a new terminal window and navigate to the project root:

### A. Fetch Packages
Resolve dependencies:
```bash
flutter pub get
```

### B. Configure Client Environment
Create a client configuration file or set your local IP in your network utilities configuration to point to `http://127.0.0.1:8000` (or `10.0.2.2` when running inside an Android Emulator).

### C. Run the Application
Start the mobile application:
```bash
flutter run
```
To run the Web preview (utilizes Device Preview layout):
```bash
flutter run -d chrome
```

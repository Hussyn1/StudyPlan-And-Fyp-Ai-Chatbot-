# Intelligent Academic Mentor & Hybrid FYP Recommendation System

> **Research-Based Adaptation of Large Language Models for Personalized Education**

## 1. Abstract / System Overview
This project presents an **AI-driven Academic Mentor and Final Year Project (FYP) Recommendation System** designed to bridge the gap between static curriculum management and personalized student guidance. Unlike traditional learning management systems (LMS), this system employs a **Hybrid Intelligence Architecture**—combining deterministic heuristic algorithms with Generative AI (LLMs)—to offer real-time study planning, adaptive task generation, and career-aligned project recommendations.

The system addresses three core educational challenges:
1.  **Passive Learning:** By actively generating personalized tasks rather than just tracking grades.
2.  **Guidance Void:** By providing a context-aware 24/7 mentor that understands the student's specific academic history.
3.  **Project Mismatches:** By using a weighted multi-variable algorithm to match students with FYPs that align with their actual skills, not just their GPA.

---

## 2. Research Methodology & Algorithmic Innovation

The core research value of this system lies in its two primary algorithmic implementations: the **Hybrid FYP Recommender** and the **Context-Injected Chatbot pipeline**.

### 2.1 The Hybrid Recommendation Algorithm (Deterministic + Generative)
To solve the "Cold Start" and "Relevance" problems in project recommendation, we devised a two-stage approach:

**Stage 1: Deterministic Weighted Heuristics (Filtering & Scoring)**
We define a mathematical scoring model `S(p, s)` for a project `p` and student `s`, based on three vectors:
*   **Skill Validity ($V_k$):** Derived from the intersection of project requirements and the student's normalized `Progress` matrix (grades converted to 1-5 skill stars).
*   **Interest Alignment ($I_a$):** Semantic matching between student declared interests and project categories.
*   **Market Trend ($T_m$):** A boolean bias towards currently trending technologies (e.g., AI/ML).

**Formula:**
$$ Score = (V_k \times 0.4) + (I_a \times 0.5) + (T_m \times 0.1) $$

*Note: The implementation uses a point-based variation (20/30/10 points) which is mathematically equivalent to the weighted ratio.*

**Stage 2: Generative Explanation & Refinement**
Raw scores tell a student *what* is good, but not *why*. The top $N$ candidates from Stage 1 are passed to the **LLM (Large Language Model)** along with the student's profile.
*   **Input:** Structured JSON of top projects + Student Metrics.
*   **Prompt Engineering:** The LLM acts as a "Senior Career Counselor" to rewrite the technical description into a personalized value proposition (e.g., *"Since you excelled in Data Structures, this project's algorithmic complexity is a perfect challenge for you..."*).

### 2.2 Context-Retrieval Augmented Generation (CRAG-lite)
Standard chatbots hallucinate or give generic advice. We implemented a **stateless but context-rich pipeline** to ensure high fidelity interactions without vector database complexity.

**The Context Injection Protocol:**
Before *any* response is generated, the backend aggregates a 4-dimensional context vector:
1.  **Static Profile:** Name, Semester, Learning Style (Visual/Reading), Pace.
2.  **Academic State:** Current enrolled courses list.
3.  **Performance History:** Last 5 tasks attempted (Success/Fail status).
4.  **Conversation Window:** Last 5 turns of chat history.

This context is injected into the **System Prompt** dynamically.
*   *Result:* If a student asks "Give me a task," the AI doesn't ask "For which subject?"; it looks at their lowest-performing active course and generates a remedial task automatically.

---

## 3. System Architecture

The system follows a **Microservices-oriented Monolith** architecture to ensure scalability and separation of concerns.

### 3.1 Tech Stack
*   **Frontend:** Flutter (Dart) - Cross-platform mobile application with reactive state management (GetX).
*   **Backend:** Python (FastAPI) - High-performance async API.
*   **Database:** MongoDB (NoSQL) with **Beanie ODM** - Allowing flexible schema evolution for student profiles.
*   **AI Inference Layer:**
    *   **Orchestrator:** `ai_service.py` (Local Service Wrapper).
    *   **Models:** Support for **Gemini 1.5 Pro** (Cloud) and **Llama 3** (via Ollama Local) for privacy-centric deployments.

### 3.2 Key Data Flows
1.  **Enrollment Flow:**
    `User Enrolls` -> `Generate Course Topics` -> `Create Progress Tracker` (Zero State).
2.  **Task Verification Flow:**
    `Student Submit(Text)` -> `AI Grader(Prompt: "Act as TA")` -> `Score 0-100` -> `Update Skill Matrix`.
3.  **Study Plan Flow:**
    `Request Plan` -> `Fetch Weak Areas` + `Fetch Available Time` -> `Constraint Satisfaction (LLM)` -> `Markdown Schedule`.

---

## 4. Unique Features & Novelty

### 4.1 Adaptive Task Generation
Unlike platforms with static question banks, our system generates tasks **on-the-fly**.
*   **Variable Difficulty:** If a student fails a "Loops" task, the next generated task will be downgraded to "Theory/Concept" level automatically.
*   **Style-Matched:** "Visual" learners get prompts asking to describe diagrams; "Practice" learners get code-completion challenges.

### 4.2 Semantic Progress Tracking
Progress is not just "70% done." The system tracks specific **Knowledge Gaps**.
*   *Implementation:* Failed tasks are tagged. The "Weak Areas" service queries these tags to influence future Chatbot suggestions.

### 4.3 Automated Research Roadmaps
For FYP suggestions, the system doesn't just give a title. It generates a **4-Phase Implementation Roadmap** (Research, Design, Code, Test) and a specific **Tech Stack** tailored to the project, giving students a "Day 1" start guide.

---

## 5. Potential Future Work
To expand this research, the following modules are proposed:
1.  **Collaborative Filtering:** Incorporating peer performance data to suggest courses that similar students enjoyed.
2.  **Visual Input Analysis:** Upgrading the `verify_submission` pipeline to accept images (Multimodal LLM) for verifying UML diagrams or handwritten math.
3.  **Long-term Retention Analysis:** Using spaced repetition algorithms (Anki-style) within the task generator to resurface old concepts before exams.

---

## 6. How to Run

### Prerequisites
*   **Python 3.10+** (FastAPI, Beanie, Motor)
*   **Flutter SDK** (3.x+)
*   **MongoDB** (Local or Atlas)
*   **Ollama/Gemini API Key**

### Backend Setup
```bash
cd backend
pip install -r requirements.txt
# Configure .env with AI_API_KEY
python main.py
```

### Frontend Setup
```bash
cd flutter_app
flutter pub get
flutter run
```

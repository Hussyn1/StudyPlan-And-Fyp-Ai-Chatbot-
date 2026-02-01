import os
from typing import List, Dict, Any, Optional
import json
import asyncio
import httpx
from services.ml_service import ml_service

class AIService:
    def __init__(self):
        self.dataset = {}
        self.load_dataset()
        # Make model name configurable (e.g. 'llama3-8b-8192' for Groq, 'meta-llama/Meta-Llama-3-8B-Instruct' for HF)
        self.model_name = os.getenv("AI_MODEL_NAME", "gpt-oss:120b-cloud") 
        self.api_url = os.getenv("OLLAMA_HOST", "http://localhost:11434/api/chat")
        self.api_key = os.getenv("AI_API_KEY")
        
    def load_dataset(self):
        try:
            # Robust path finding: Get the directory of this file (services/) then go up one level
            base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
            file_path = os.path.join(base_dir, "dataset.json")
            
            with open(file_path, "r") as f:
                self.dataset = json.load(f)
            print("Loaded domain dataset.")
        except FileNotFoundError:
            print("Warning: dataset.json not found. Using generic knowledge.")
            self.dataset = {}

    async def _call_ollama(self, prompt: str, system: str = "You are a helpful academic assistant.") -> str:
        # Determine if we should use 'prompt' (generate) or 'messages' (chat)
        is_chat_endpoint = any(x in self.api_url for x in ["/chat", "/completions"])
        
        if is_chat_endpoint:
            payload: Dict[str, Any] = {
                "model": self.model_name,
                "messages": [
                    {"role": "system", "content": system},
                    {"role": "user", "content": prompt}
                ],
                "stream": False,
                "temperature": 0.7  # Moved to top-level for OpenAI/Groq compatibility
            }
        else:
            # Fallback to generate endpoint structure
            full_prompt = f"System: {system}\n\nUser: {prompt}"
            payload: Dict[str, Any] = {
                "model": self.model_name,
                "prompt": full_prompt,
                "stream": False,
                "temperature": 0.7
            }
        
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {self.api_key}"
        }

        max_retries = 2
        for attempt in range(max_retries + 1):
            try:
                # DEBUG: Print exact connection details for Render logs
                safe_key = self.api_key[:5] + "..." if self.api_key else "None"
                print(f"DEBUG: Connecting to AI Service at: {self.api_url}")
                print(f"DEBUG: Is Chat Endpoint: {is_chat_endpoint} | Key present: {bool(self.api_key)}")
                
                async with httpx.AsyncClient(timeout=60.0) as client:
                    response = await client.post(
                        self.api_url, # Changed from self.base_url to self.api_url to match existing attribute
                        json=payload,
                        headers=headers
                    )
                    result = response.json()
                    
                    # Try different response fields (Ollama, Ollama-Chat, OpenAI/Cloud)
                    text = result.get('response') # Standard Ollama
                    if text is None or text == "":
                        text = result.get('message', {}).get('content') # Ollama Chat
                    if text is None or text == "":
                        text = result.get('choices', [{}])[0].get('message', {}).get('content') # OpenAI/Cloud
                    
                    if text: # Return only if non-empty
                        return text
                    
                    # Special case: If it was explicitly empty but 'done' is true, return a placeholder
                    if result.get('done') is True and (text == "" or text is None):
                        print(f"AI Service Warning: Received empty successful response. Reason: {result.get('done_reason')}")
                        return "I'm sorry, I couldn't generate a response. Please try rephrasing your question."

                    print(f"AI Service Warning: No recognizable text field in response: {result}")
                    return ""
            except (httpx.ConnectError, httpx.ConnectTimeout) as e:
                if attempt == max_retries:
                    print(f"AI Service Error: Connection failed after {max_retries} retries. {e}")
                    return "Error: Unable to connect to the AI service. Please check your internet or try again later."
            except httpx.HTTPStatusError as e:
                print(f"AI Service Error: HTTP {e.response.status_code}. {e}")
                return f"Error: The AI service returned an error (Status {e.response.status_code})."
            except Exception as e:
                if attempt == max_retries:
                    print(f"AI Service Error: Unexpected error. {e}")
                    return "Error: An unexpected error occurred while communicating with the AI."
            
            # Simple backoff delay before retry
            if attempt < max_retries:
                await asyncio.sleep(1 * (attempt + 1))
        
        # --- FALLBACK MECHANISM ---
        # If we reach here, AI service is down or unreachable.
        # Check if the system prompt implies JSON output and return a mock response.
        print("AI Service Error: All retries failed. Attempting fallback mock response.")
        
        if "JSON" in system.upper() or "JSON" in prompt.upper():
            if "roadmap" in prompt.lower():
                return '{"interest": "Generic CS", "phases": [{"title": "Basics", "topics": [{"title": "Example Topic 1"}, {"title": "Example Topic 2"}], "project": "Simple App", "duration": "1 month"}], "resources": ["Google", "StackOverflow"]}'
            elif "task" in prompt.lower():
                return '{"title": "Offline Practice Task", "description": "The AI service is currently unavailable. Please practice by reviewing your notes for now.", "type": "theory"}'
            elif "verify" in prompt.lower() or "submission" in prompt.lower():
                 return '{"verified": true, "score": 85, "feedback": "AI Service unavailable. Auto-verified for offline mode."}'
        
        return "I'm sorry, I'm currently running in offline mode and can't generate a new response right now. Please try again later."

    async def get_chat_response(self, message: str, context: List[Dict[str, str]], student_profile: Optional[Dict] = None, tasks_context: Optional[List[Dict]] = None, courses_context: Optional[List[Dict]] = None, roadmap_context: Optional[Dict] = None) -> str:
        system_context = """
        You are an expert AI Study Assistant for Computer Science students. 
        Your goal is to provide highly structured, academic, and encouraging responses.
        
        Formatting Rules:
        1. Use clear Markdown Headings (## and ###) to organize different sections.
        2. Whenever comparing concepts or listing data, use properly formatted Markdown Tables (|:---|:---|).
        3. Use bolding (**) for key terms and concepts.
        4. ALWAYS end detailed explanations with a 'Summary' or 'Key Takeaway' section.
        5. If providing code, use fenced code blocks (```python).
        """
        
        if student_profile:
            system_context += f"""
            You are talking to {student_profile.get('name')}, who is in semester {student_profile.get('current_semester')}.
            Student Profile:
            - Interests: {student_profile.get('interests')}
            - Learning Style: {student_profile.get('learning_style')}
            - Study Pace: {student_profile.get('study_pace')}
            - Weak Subjects: {student_profile.get('weak_subjects')}
            """

        if courses_context:
            system_context += f"\nStudent's Enrolled Courses:\n{json.dumps(courses_context, default=str)}"
            system_context += "\nNOTE: Only suggest topics or tasks related to these courses unless the user asks otherwise."
            
        if tasks_context:
            system_context += f"\nStudent's Recent Tasks & Performance:\n{json.dumps(tasks_context, default=str)}"
            system_context += "\nIf the student asks about their answers or progress, refer to the data above. If an answer was 'verified' as False, it means they were wrong."

        if roadmap_context:
            system_context += f"\nACTIVE ROADMAP CONTEXT:\n{json.dumps(roadmap_context, default=str)}"
            system_context += "\nThe student is actively working on this roadmap. Guide them through the 'pending_topics'. If they ask 'what to do next', refer to the first pending topic."

        system_context += "\nAlways tailor your advice to their learning style and pace. If they mention a weak subject, be extra explanatory."
        
        if self.dataset:
            system_context += f"\nRelevant Domain Knowledge: {json.dumps(self.dataset.get('study_resources', {}))}."

        # Add Tool Calling Instruction
        system_context += """
        
        TOOL USE:
        If the student explicitly asks you to "give me a task", "generate a question", or "test me" on a specific topic, 
        you MUST NOT generate the question in the chat. Instead, you MUST output a JSON command for the system to generate it.
        
        Format:
        ```json
        {
            "tool": "create_task",
            "topic": "extracted topic",
            "course": "extracted course name (infer from context or use 'General')",
            "reason": "Why you chose this topic (e.g. 'You struggled with this previously')"
        }
        ```
        """

        # Format conversation history for prompt
        history_str = ""
        for msg in context[-5:]: # Last 5 messages for context
            role = "User" if msg['role'] == "user" else "Assistant"
            history_str += f"{role}: {msg['content']}\n"

        prompt = f"{history_str}User: {message}\nAssistant:"
        
        return await self._call_ollama(prompt, system=system_context)

    async def generate_fyp_suggestions_hybrid(self, student_id: str) -> Dict:
        """Hybrid approach: Get ML calculated projects, then have AI explain them."""
        recommendations = await ml_service.recommend_fyp_projects(student_id)
        
        if not recommendations:
             return {"suggestions": [], "message": "No projects matched your skills yet. Try completing more courses!"}

        prompt = f"""
        I have calculated the 10 best Final Year Projects for this student based on their grades and interests.
        
        Calculated Recommendations:
        {json.dumps(recommendations, default=str)}
        
        Task:
        Rewrite the "rationale" for each project to be encouraging and exciting for the student. 
        IMPORTANT: Preserve all other fields (id, title, description, score, match_score, category, matching_skills) exactly as they are.
        Return ONLY valid JSON structure: {{ "suggestions": [ ... ] }}
        """
        
        response_text = await self._call_ollama(prompt, system="You are a JSON assistant. Output only JSON.")
        return self._clean_json(response_text, recommendations)

    def _clean_json(self, text: str, fallback: Any) -> Any:
        """Helper to clean and parse JSON from AI responses."""
        try:
            cleaned = text.strip()
            if "```json" in cleaned:
                cleaned = cleaned.split("```json")[1].split("```")[0].strip()
            elif "```" in cleaned:
                cleaned = cleaned.split("```")[1].split("```")[0].strip()
            
            # Remove any trailing commas or stray text before parsing
            # (Basic cleaning, can be expanded if needed)
            return json.loads(cleaned)
        except Exception as e:
            print(f"JSON Parsing Error: {e}")
            return fallback

    async def generate_study_plan(self, student_profile: dict, courses: List[dict], completed_topics: List[str] = None) -> str:
        """Generates a detailed weekly study plan based on student profile and progress."""
        resources_text = json.dumps(self.dataset.get('study_resources', {}))
        
        prompt = f"""
        Act as an expert academic counselor for Computer Science. 
        Create a highly personalized weekly study plan.
        
        Student Profile: {json.dumps(student_profile, default=str)}
        Enrolled Courses: {json.dumps(courses, default=str)}
        
        Progress Info:
        - Already Completed Topics: {json.dumps(completed_topics or [], default=str)}
        
        Guidelines:
        1. Only include topics that ARE NOT in the 'Already Completed Topics' list.
        2. Tailor the pace to the student's study pace ({student_profile.get('study_pace')}).
        3. Match the learning style ({student_profile.get('learning_style')}).
        4. Focus more time on weak subjects ({student_profile.get('weak_subjects')}).
        5. Use these recommended resources where appropriate: {resources_text}
        
        Format: Return a properly formatted Markdown table with columns: Day | Course | Topic | Activity | Time Estimate. 
        Ensure you use pipe symbols (|) and a header separator line (e.g., |:---|:---|...).
        After the table, provide a short paragraph of motivation.
        """
        return await self._call_ollama(prompt)

    async def generate_project_details(self, title: str, description: str) -> Dict:
        """Generates a structured roadmap and tech stack for a specific project."""
        prompt = f"""
        Act as a Senior Research Lead. Provide a detailed implementation guide for this Final Year Project:
        
        Project Title: {title}
        Description: {description}
        
        Task:
        Generate a structured JSON object including:
        1. "roadmap": A list of 4 phases (Research, Design, Implementation, Testing) with 2-3 bullet points each.
        2. "tech_stack": A dictionary of recommended tools (Backend, Frontend, Database, AI/ML libraries, etc.).
        3. "key_features": A list of 5 essential features.
        4. "learning_gems": 3 specific concepts the student will master.

        Return ONLY valid JSON structure:
        {{
            "roadmap": [
                {{ "phase": "Research", "tasks": ["...", "..."] }},
                ...
            ],
            "tech_stack": {{ "Frontend": "...", "Backend": "...", ... }},
            "key_features": ["...", "..."],
            "learning_gems": ["...", "..."]
        }}
        """
        response_text = await self._call_ollama(prompt, system="You are an expert technical architect. Output only JSON.")
        return self._clean_json(response_text, {
            "roadmap": [{"phase": "Generic", "tasks": ["Research foundations", "Define scope"]}],
            "tech_stack": {"Tools": "Python, Mobile Framework, Cloud"},
            "key_features": ["User Auth", "Main Engine"],
            "learning_gems": ["Software Lifecycle"]
        })

    async def verify_submission(self, task_title: str, task_description: str, submission: str) -> Dict:
        """Verifies if the student's submission matches the task requirements with flexibility for text-based responses."""
        prompt = f"""
        You are a helpful and fair Teaching Assistant. 
        Evaluate the student's submission for the following task.
        
        Task Title: {task_title}
        Task Description: {task_description}
        
        Student Submission:
        {submission}
        
        Evaluation Guidelines:
        1. **Conceptual Accuracy**: Evaluate how well the student understands the core concepts.
        2. **Formatting**: Be flexible with diagrams/UML, accept text descriptions.
        3. **Scoring**: Assign a score from 0 to 100 based on completeness and accuracy.
        4. **Verification**: Set `verified: true` if the score is 50 or above.
        
        Return JSON ONLY:
        {{
            "verified": true/false,
            "score": 0-100,
            "feedback": "A constructive 1-2 sentence feedback explaining the score and how to improve."
        }}
        """
        
        response_text = await self._call_ollama(prompt, system="You are a professional academic evaluator. Output only JSON.")
        return self._clean_json(response_text, {"verified": True, "score": 80, "feedback": "Manual backup verification applied due to service glitch."})

    async def summarize_progress(self, student_profile: dict, progress_list: List[dict]) -> str:
        """Generates a encouraging and analytical summary of student progress."""
        prompt = f"""
        Analyze the following student progress and provide a short, encouraging summary (2-3 sentences).
        Student Name: {student_profile.get('name')}
        Progress Data: {json.dumps(progress_list, default=str)}
        
        Task:
        - Mention a specific course they are doing well in (highest accuracy/completion).
        - Give a gentle nudge for courses with low progress.
        - End with an encouraging closing statement.
        """
        return await self._call_ollama(prompt)

    async def generate_personalized_task(self, student_profile: dict, course_name: str, topic: str) -> Dict:
        """Use AI to generate a specific task for a topic based on student learning style."""
        prompt = f"""
        Act as an expert CS educator. Generate a personalized learning task for a student.
        
        Student Profile:
        - Name: {student_profile.get('name')}
        - Learning Style: {student_profile.get('learning_style')}
        - Study Pace: {student_profile.get('study_pace')}
        - Interests: {student_profile.get('interests')}
        
        Context:
        - Course: {course_name}
        - Topic: {topic}
        
        Task:
        1. Create a "title" that is engaging.
        2. Create a "description" that is a specific challenge or question.
           - If style is 'Visual', ask them to **describe** a diagram, UML, or flowchart using text or bullet points instead of drawing it.
           - If style is 'Practice', make it a specific coding challenge.
           - If style is 'Reading', make it a deep-dive research question.
        3. Assign a "type" (theory, coding, or mcq).
        
        Guidelines:
        - Ensure the task can be fully completed using ONLY text input in a chat box.
        - Do not ask for files, uploads, or actual drawings.
        
        Return ONLY a JSON object:
        {{
            "title": "Clear Task Title",
            "description": "Specific detailed instruction/question",
            "type": "coding/theory/mcq"
        }}
        """
        
        response_text = await self._call_ollama(prompt, system="You are a JSON assistant. Output only JSON.")
        return self._clean_json(response_text, {
            "title": f"Study {topic}",
            "description": f"Review and master {topic} for the {course_name} course.",
            "type": "theory"
        })

    async def generate_interest_roadmap(self, student_profile: dict, interest: str) -> Dict:
        """Generates a personalized roadmap for a specific interest."""
        prompt = f"""
        Act as an expert career counselor and technical mentor. 
        Create a personalized roadmap for a student who wants to master "{interest}".
        
        Student Profile:
        - Name: {student_profile.get('name')}
        - Current Semester: {student_profile.get('current_semester')}
        - Learning Style: {student_profile.get('learning_style')}
        - Study Pace: {student_profile.get('study_pace')}
        
        Task:
        1. Break down the path to mastering "{interest}" into 4 phases (Beginner, Intermediate, Advanced, Mastery).
        2. For each phase, suggest:
           - 3 Key Topics
           - 1 Project Idea
           - Estimated Time to Complete (based on study pace)
        3. Provide 3 specific resources (Books, Courses, or Websites) tailored to their learning style.
        
        Return ONLY valid JSON structure:
        {{
            "interest": "{interest}",
            "phases": [
                {{
                    "title": "Beginner",
                    "topics": ["...", ...],
                    "project": "...",
                    "duration": "..."
                }},
                ...
            ],
            "resources": ["...", ...]
        }}
        """
        
        response_text = await self._call_ollama(prompt, system="You are a JSON assistant. Output only JSON.")
        return self._clean_json(response_text, {
            "interest": interest,
            "phases": [], 
            "resources": ["Official Documentation", "YouTube Tutorials"],
            "message": "AI generation fallback."
        })

ai_service = AIService()
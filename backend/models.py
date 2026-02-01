from typing import List, Optional
from beanie import Document, Link
from pydantic import BaseModel
from datetime import datetime

class Course(Document):
    name: str
    code: str
    description: Optional[str] = None
    semester: int
    topics: List[str] = []

    class Settings:
        name = "courses"

class Student(Document):
    roll_number: str
    password: str  # Added for authentication
    name: str
    uni_name: str
    current_semester: int
    interests: List[str] = []
    weak_subjects: List[str] = []
    study_pace: str  # Slow, Moderate, Fast
    learning_style: str # Visual, Reading, Practice
    
    class Settings:
        name = "students"

class Task(Document):
    title: str
    description: str
    course_id: Optional[str] = None
    student_id: str
    status: str = "pending" # pending, completed
    type: str # theory, coding, mcq
    difficulty: str # easy, medium, hard
    created_at: datetime = datetime.now()
    completed_at: Optional[datetime] = None
    ai_feedback: Optional[str] = None
    verified: Optional[bool] = None
    score: int = 0  # Percentage score (0-100)
    submission: Optional[str] = None
    
    class Settings:
        name = "tasks"

class Progress(Document):
    student_id: str
    course_id: str
    course_name: Optional[str] = None
    tasks_completed: int = 0
    total_tasks: int = 0
    accuracy: float = 0.0
    grade: Optional[float] = None  # Added for ML services (0-100)
    status: str = "ongoing" # ongoing, completed
    
    class Settings:
        name = "progress"

class FYPProject(Document):
    title: str
    description: str
    category: str # e.g. "AI", "Web", "Network"
    complexity: str # "Easy", "Medium", "Hard"
    required_skills: List[str] = []
    trending: bool = False
    
    class Settings:
        name = "fyp_projects"

class ChatMessage(BaseModel):
    role: str # user, model
    content: str
    timestamp: datetime = datetime.now()

class ChatSession(Document):
    student_id: str
    messages: List[ChatMessage] = []
    
    class Settings:
        name = "chat_sessions"

class RoadmapTopic(BaseModel):
    title: str
    status: str = "pending" # pending, in_progress, completed
    resources: List[str] = []

class RoadmapPhase(BaseModel):
    title: str # Beginner, Intermediate, etc.
    topics: List[RoadmapTopic] = []
    project: Optional[str] = None
    duration: Optional[str] = None
    is_completed: bool = False

class StudentRoadmap(Document):
    student_id: str
    interest: str
    phases: List[RoadmapPhase] = []
    current_phase_index: int = 0
    created_at: datetime = datetime.now()
    updated_at: datetime = datetime.now()

    class Settings:
        name = "student_roadmaps"
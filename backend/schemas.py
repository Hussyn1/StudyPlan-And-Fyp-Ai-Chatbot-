# schemas.py - Pydantic Schemas for API validation
from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime

# Student Schemas
class StudentCreate(BaseModel):
    email: EmailStr
    name: str
    roll_number: str
    university: str
    current_semester: int
    study_pace: str  # slow, moderate, fast
    learning_style: str  # visual, reading, practice
    daily_study_hours: float
    career_goal: str
    interests: str  # JSON string

class StudentResponse(BaseModel):
    id: int
    email: str
    name: str
    roll_number: str
    current_semester: int
    study_pace: str
    
    class Config:
        from_attributes = True

# Course Schemas
class CourseCreate(BaseModel):
    code: str
    name: str
    semester: int
    credits: int
    prerequisites: Optional[str] = None
    description: Optional[str] = None

class CourseResponse(BaseModel):
    id: int
    code: str
    name: str
    semester: int
    credits: int
    
    class Config:
        from_attributes = True

# Student Course Enrollment
class StudentCourseCreate(BaseModel):
    student_id: int
    course_id: int
    status: str  # ongoing, completed, failed
    grade: Optional[float] = None

class StudentCourseResponse(BaseModel):
    id: int
    course_id: int
    grade: Optional[float]
    status: str
    
    class Config:
        from_attributes = True

# Task Schemas
class TaskCreate(BaseModel):
    course_id: int
    title: str
    description: str
    difficulty: int  # 1-5
    topic: str
    task_type: str  # coding, mcq, theory
    points: int

class TaskResponse(BaseModel):
    id: int
    title: str
    description: str
    difficulty: int
    topic: str
    task_type: str
    points: int
    
    class Config:
        from_attributes = True

# Student Task Submission
class TaskSubmission(BaseModel):
    student_id: int
    task_id: int
    submitted_answer: str
    time_spent: float  # in minutes

class StudentTaskResponse(BaseModel):
    id: int
    task_id: int
    attempts: int
    status: str
    score: Optional[float]
    time_spent: Optional[float]
    
    class Config:
        from_attributes = True

# FYP Schemas
class FYPProjectCreate(BaseModel):
    title: str
    description: str
    complexity: str
    required_skills: str  # JSON string
    category: str
    trending: bool
    preparation_months: int

class FYPProjectResponse(BaseModel):
    id: int
    title: str
    description: str
    complexity: str
    category: str
    trending: bool
    preparation_months: int
    match_score: Optional[float] = None  # Added during recommendation
    
    class Config:
        from_attributes = True

# Study Plan Schema
class StudyPlanResponse(BaseModel):
    id: int
    week_number: int
    semester: int
    tasks_assigned: str
    completion_rate: float
    created_at: datetime
    
    class Config:
        from_attributes = True

# Chat Schema
class ChatRequest(BaseModel):
    student_id: int
    message: str

class ChatResponse(BaseModel):
    response: str
    timestamp: datetime

# Dashboard Analytics
class StudentAnalytics(BaseModel):
    total_courses_completed: int
    current_courses: int
    total_tasks_solved: int
    average_score: float
    strong_areas: List[dict]
    weak_areas: List[dict]
    skill_matrix: dict
    learning_velocity: str  # improving, stable, declining
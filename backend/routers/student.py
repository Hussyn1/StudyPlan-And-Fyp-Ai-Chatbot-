from fastapi import APIRouter, HTTPException
from models import Student, Task, Progress, Course
from services.ai_service import ai_service
from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel

router = APIRouter()

class StudentCreate(BaseModel):
    roll_number: str
    password: str
    name: str
    uni_name: str
    current_semester: int
    interests: List[str] = []
    weak_subjects: List[str] = []
    study_pace: str = "Moderate"
    learning_style: str = "Reading"

class StudentUpdate(BaseModel):
    interests: Optional[List[str]] = None
    weak_subjects: Optional[List[str]] = None
    study_pace: Optional[str] = None
    learning_style: Optional[str] = None

class EnrollmentRequest(BaseModel):
    course_ids: List[str]

@router.post("/students")
async def create_student(student_data: StudentCreate):
    student = Student(**student_data.dict())
    await student.insert()
    return student

@router.get("/students/{student_id}")
async def get_student(student_id: str):
    student = await Student.get(student_id)
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    return student

@router.put("/students/{student_id}")
async def update_student(student_id: str, update_data: StudentUpdate):
    student = await Student.get(student_id)
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    data = update_data.dict(exclude_unset=True)
    for key, value in data.items():
        setattr(student, key, value)
    
    await student.save()
    return student

@router.get("/courses/semester/{semester}")
async def get_semester_courses(semester: int):
    courses = await Course.find(Course.semester == semester).to_list()
    return courses

@router.post("/students/{student_id}/enroll")
async def enroll_courses(student_id: str, enrollment: EnrollmentRequest):
    student = await Student.get(student_id)
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    # Initialize progress for each enrolled course
    for course_id in enrollment.course_ids:
        course = await Course.get(course_id)
        if course:
            # Check if progress already exists
            existing = await Progress.find_one(
                Progress.student_id == student_id,
                Progress.course_id == course_id
            )
            if not existing:
                progress = Progress(
                    student_id=student_id,
                    course_id=course_id,
                    course_name=course.name,
                    total_tasks=len(course.topics) # Simple logic: 1 task per topic
                )
                await progress.insert()
                
                # Generate tasks for this course
                await generate_tasks_for_student(student_id, course_id)
    
    return {"status": "success", "message": "Enrolled in courses and tasks generated"}

@router.get("/progress/{student_id}")
async def get_progress(student_id: str):
    progress = await Progress.find(Progress.student_id == student_id).to_list()
    return progress

@router.get("/tasks/{student_id}")
async def get_tasks(student_id: str, course_id: Optional[str] = None):
    if course_id:
        tasks = await Task.find(Task.student_id == student_id, Task.course_id == course_id).to_list()
    else:
        tasks = await Task.find(Task.student_id == student_id).to_list()
    return tasks

@router.post("/tasks/submit")
async def submit_task(student_id: str, task_id: str, submission_content: str):
    task = await Task.get(task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    if task.status == "completed":
        return {"status": "success", "message": "Task already completed"}

    task.status = "completed"
    task.completed_at = datetime.now()
    await task.save()
    
    # Update progress
    if task.course_id:
        progress = await Progress.find_one(
            Progress.student_id == student_id,
            Progress.course_id == task.course_id
        )
        if progress:
            progress.tasks_completed += 1
            if progress.total_tasks > 0:
                progress.accuracy = (progress.tasks_completed / progress.total_tasks)
            
            if progress.tasks_completed == progress.total_tasks:
                progress.status = "completed"
            
            await progress.save()
    
    return {"status": "success", "message": "Task submitted and progress updated"}

class TaskSubmission(BaseModel):
    submission_content: str

@router.post("/tasks/{task_id}/verify")
async def verify_task(task_id: str, submission: TaskSubmission):
    task = await Task.get(task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
        
    if task.status == "completed":
        return {"status": "success", "verified": True, "message": "Task already completed"}

    # AI Verification
    verification_result = await ai_service.verify_submission(
        task.title,
        task.description,
        submission.submission_content
    )
    
    if verification_result.get("verified", False):
        # Mark as completed if verified
        task.status = "completed"
        task.completed_at = datetime.now()
        await task.save()
        
        # Update progress (Reusing logic)
        if task.course_id:
            progress = await Progress.find_one(
                Progress.student_id == task.student_id,
                Progress.course_id == task.course_id
            )
            if progress:
                progress.tasks_completed += 1
                if progress.total_tasks > 0:
                    progress.accuracy = (progress.tasks_completed / progress.total_tasks)
                
                if progress.tasks_completed == progress.total_tasks:
                    progress.status = "completed"
                
                await progress.save()
                
        return {
            "status": "success", 
            "verified": True, 
            "message": "Great job! Your submission was accepted.",
            "feedback": verification_result.get("feedback")
        }
    else:
        return {
            "status": "success", 
            "verified": False, 
            "message": "Submission needs improvement.",
            "feedback": verification_result.get("feedback")
        }

@router.post("/tasks/{task_id}/ai-generate")
async def generate_task_content(task_id: str):
    task = await Task.get(task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
        
    if task.description and "Practice:" in task.title: # Simple check if already AI-fied
        return task

    student = await Student.get(task.student_id)
    course = await Course.get(task.course_id)
    
    if not student or not course:
         raise HTTPException(status_code=404, detail="Student or Course not found")

    # Call AI service to generate a real task
    ai_task = await ai_service.generate_personalized_task(
        student.dict(), 
        course.name, 
        task.title # The topic is currently stored in title
    )
    
    task.title = ai_task.get("title", task.title)
    task.description = ai_task.get("description", task.description)
    task.type = ai_task.get("type", task.type)
    
    await task.save()
    return task

async def generate_tasks_for_student(student_id: str, course_id: str):
    course = await Course.get(course_id)
    if not course:
        return
    
    # Create a task for each topic
    for topic in course.topics:
        # Check if task already exists
        existing = await Task.find_one(
            Task.student_id == student_id,
            Task.course_id == course_id,
            Task.title == topic
        )
        if not existing:
            task = Task(
                student_id=student_id,
                course_id=course_id,
                title=topic,
                description=f"Learn and master the concepts of {topic} in {course.name}.",
                type="theory",
                difficulty="medium"
            )
            await task.insert()

@router.get("/fyp/suggestions/{student_id}")
async def get_fyp_suggestions(student_id: str):
    student = await Student.get(student_id)
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
        
    # Restrict to Final Year Students (Sem 7+)
    if student.current_semester < 7:
        return {
            "suggestions": [],
            "message": f"FYP suggestions are unlocked in Semester 7. You are currently in Semester {student.current_semester}. Keep focusing on your coursework!"
        }

    # Use Hybrid Service
    suggestions = await ai_service.generate_fyp_suggestions_hybrid(student_id)
    return suggestions
@router.get("/students/{student_id}/study-plan")
async def get_study_plan(student_id: str):
    student = await Student.get(student_id)
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    # Get enrolled courses
    progress_records = await Progress.find(Progress.student_id == student_id).to_list()
    courses = []
    for pr in progress_records:
        courses.append({"id": pr.course_id, "name": pr.course_name})
    
    # Get completed topics from completed tasks
    completed_tasks = await Task.find(
        Task.student_id == student_id,
        Task.status == "completed"
    ).to_list()
    completed_topics = [t.title for t in completed_tasks]
    
    plan = await ai_service.generate_study_plan(student.dict(), courses, completed_topics)
    return {"study_plan": plan}

@router.get("/students/{student_id}/progress-summary")
async def get_progress_summary(student_id: str):
    student = await Student.get(student_id)
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
        
    progress_list = await Progress.find(Progress.student_id == student_id).to_list()
    
    summary = await ai_service.summarize_progress(
        student.dict(), 
        [p.dict() for p in progress_list]
    )
    return {"summary": summary}

from fastapi import APIRouter, HTTPException
from models import Student, Task, Progress, Course, FYPProject, StudentRoadmap, RoadmapPhase, RoadmapTopic
from services.ai_service import ai_service
from services.ml_service import ml_service
from utils.csv_manager import csv_manager
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
    name: Optional[str] = None
    uni_name: Optional[str] = None
    current_semester: Optional[int] = None
    interests: Optional[List[str]] = None
    weak_subjects: Optional[List[str]] = None
    study_pace: Optional[str] = None
    learning_style: Optional[str] = None

class RoadmapStatusUpdate(BaseModel):
    status: str

class EnrollmentRequest(BaseModel):
    course_ids: List[str]

class TaskSubmissionRequest(BaseModel):
    student_id: str
    task_id: str
    submission_content: str

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
    courses = csv_manager.get_semester_courses(semester)
    return courses

@router.post("/students/{student_id}/enroll")
async def enroll_courses(student_id: str, enrollment: EnrollmentRequest):
    student = await Student.get(student_id)
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    # Initialize progress for each enrolled course
    for course_id in enrollment.course_ids:
        # course = await Course.get(course_id) # Old Mongo way
        
        # Check CSV for course
        course = None
        for c in csv_manager.get_courses():
            if str(c['id']) == str(course_id):
                course = c
                break
        
        if course:
            # Check if progress already exists
            existing = await Progress.find_one(
                Progress.student_id == student_id,
                Progress.course_id == str(course_id)
            )
            if not existing:
                progress = Progress(
                    student_id=student_id,
                    course_id=str(course_id),
                    course_name=course['name'],
                    total_tasks=len(course.get('topics', [])) # Use CSV topics
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
async def submit_task(submission: TaskSubmissionRequest):
    task = await Task.get(submission.task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    # Store submission
    task.submission = submission.submission_content
    
    # AI Verification
    try:
        verification = await ai_service.verify_submission(
            task.title,
            task.description,
            submission.submission_content
        )
    except Exception as e:
        print(f"Error during AI verification: {e}")
        return {
            "status": "error",
            "message": "AI Verification service is temporarily unavailable. Your work is saved, please try verifying again later.",
            "verified": False,
            "feedback": "Connectivity error."
        }
    
    task.ai_feedback = verification.get("feedback", "No feedback provided.")
    task.score = verification.get("score", 0)
    task.verified = verification.get("verified", task.score >= 50)
    
    # Ensure a non-zero score if verified but AI returned 0 or missing score
    if task.verified and task.score == 0:
        task.score = 70
    
    print(f"DEBUG: Task {submission.task_id} score: {task.score}, verified: {task.verified}")

    if task.verified:
        task.status = "completed"
        task.completed_at = datetime.now()
        
        # Update progress
        try:
            if task.course_id:
                progress = await Progress.find_one(
                    Progress.student_id == submission.student_id,
                    Progress.course_id == task.course_id
                )
                if progress:
                    # Get all completed tasks for this course to calculate average score
                    completed_tasks = await Task.find(
                        Task.student_id == submission.student_id,
                        Task.course_id == task.course_id,
                        Task.status == "completed"
                    ).to_list()
                    
                    # Include current task if not already in the list
                    total_scores = sum(t.score for t in completed_tasks)
                    if not any(t.id == task.id for t in completed_tasks):
                        total_scores += task.score
                        count = len(completed_tasks) + 1
                    else:
                        count = len(completed_tasks)
                    
                    progress.tasks_completed = count
                    progress.accuracy = count / progress.total_tasks if progress.total_tasks > 0 else 0
                    progress.grade = (total_scores / count) if count > 0 else 0
                    
                    print(f"DEBUG: New progress: {progress.tasks_completed}/{progress.total_tasks} (Avg Score: {progress.grade}%)")
                    
                    if progress.tasks_completed == progress.total_tasks:
                       progress.status = "completed"
                    
                    await progress.save()
        except Exception as e:
            print(f"Error updating progress: {e}")
            # We don't return error here because task was already verified and saved
    else:
        print(f"DEBUG: Task NOT verified. Feedback: {task.ai_feedback}")
    
    await task.save()
    
    return {
        "status": "success" if task.verified else "failed",
        "verified": task.verified,
        "score": task.score,
        "feedback": task.ai_feedback,
        "message": "Task submitted and graded by AI"
    }

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
    try:
        verification_result = await ai_service.verify_submission(
            task.title,
            task.description,
            submission.submission_content
        )
    except Exception as e:
        print(f"Error during AI verification: {e}")
        return {
            "status": "error", 
            "verified": False, 
            "message": "Something went wrong with AI verification. Please try again later."
        }
    
    task.score = verification_result.get("score", 0)
    task.verified = verification_result.get("verified", task.score >= 50)
    task.ai_feedback = verification_result.get("feedback", "No feedback.")

    # Ensure a non-zero score if verified but AI returned 0 or missing score
    if task.verified and task.score == 0:
        task.score = 70

    if task.verified:
        # Mark as completed if verified
        task.status = "completed"
        task.completed_at = datetime.now()
        await task.save()
        
        # Update progress
        try:
            if task.course_id:
                progress = await Progress.find_one(
                    Progress.student_id == task.student_id,
                    Progress.course_id == task.course_id
                )
                if progress:
                    completed_tasks = await Task.find(
                        Task.student_id == task.student_id,
                        Task.course_id == task.course_id,
                        Task.status == "completed"
                    ).to_list()
                    
                    total_scores = sum(t.score for t in completed_tasks)
                    if not any(t.id == task.id for t in completed_tasks):
                        total_scores += task.score
                        count = len(completed_tasks) + 1
                    else:
                        count = len(completed_tasks)
                    
                    progress.tasks_completed = count
                    progress.accuracy = count / progress.total_tasks if progress.total_tasks > 0 else 0
                    progress.grade = (total_scores / count) if count > 0 else 0
                    
                    print(f"DEBUG: New progress: {progress.tasks_completed}/{progress.total_tasks} (Avg Score: {progress.grade}%)")
                    
                    if progress.tasks_completed == progress.total_tasks:
                        progress.status = "completed"
                    
                    await progress.save()
        except Exception as e:
            print(f"Error updating progress: {e}")
        if task.verified:
            # Check for auto-generation of new tasks if this was the last one
            try:
                await check_and_generate_remedial_tasks(task.student_id)
            except Exception as e:
                print(f"Error generating remedial tasks: {e}")

            return {
                "status": "success", 
                "verified": True, 
                "score": task.score,
                "message": f"Great job! Your submission scored {task.score}%.",
                "feedback": task.ai_feedback
            }
    
    return {
        "status": "success", 
        "verified": False, 
        "score": task.score,
        "message": "Submission needs improvement.",
        "feedback": task.ai_feedback
    }

async def check_and_generate_remedial_tasks(student_id: str):
    """
    Checks if the student has completed all tasks. 
    If so, generates remedial tasks for weak areas.
    """
    # 1. Check for any pending tasks
    pending_count = await Task.find(
        Task.student_id == student_id,
        Task.status == "pending"
    ).count()
    
    if pending_count > 0:
        return # Still has work to do
        
    print(f"DEBUG: Student {student_id} has 0 pending tasks. Checking for weak areas...")
    
    # 2. Identify weak areas (Low accuracy or failed tasks)
    weak_areas = await ml_service.identify_weak_areas(student_id)
    
    if not weak_areas:
        print("DEBUG: No weak areas found. Good job!")
        return

    # 3. Generate 1 remedial task for the top weak area
    # We explicitly take only the first one to avoid overwhelming them
    target = weak_areas[0] 
    course_name = target['course_name']
    
    # Needs course_id for the task
    # Find progress record to get course_id
    progress = await Progress.find_one(
        Progress.student_id == student_id, 
        Progress.course_name == course_name
    )
    
    if not progress:
        return

    student = await Student.get(student_id)
    
    # Generate Task
    print(f"DEBUG: Generating remedial task for {course_name} (Accuracy: {target['accuracy']})")
    
    ai_task = await ai_service.generate_personalized_task(
        student.dict(),
        course_name,
        f"Remedial Practice for {course_name}" # Using course name as topic proxy for now, ideally we need granular topics
    )
    
    new_task = Task(
        student_id=student_id,
        course_id=progress.course_id,
        title=ai_task.get("title", f"Review {course_name}"),
        description=ai_task.get("description", "A personalized practice task to improve your score."),
        type=ai_task.get("type", "theory"),
        difficulty="medium",
        status="pending"
    )
    await new_task.insert()
    
    # Update Progress Stats
    progress.total_tasks += 1
    # Recalculate accuracy (denominator changed)
    progress.accuracy = progress.tasks_completed / progress.total_tasks
    # Reset status if it was completed, now they have more work!
    if progress.status == "completed":
        progress.status = "ongoing"
        
    await progress.save()
    
    print(f"DEBUG: Remedial task created: {new_task.title}. Progress updated.")

@router.post("/tasks/{task_id}/ai-generate")
async def generate_task_content(task_id: str):
    print(f"DEBUG: AI-Generate request for Task ID: {task_id}")
    task = await Task.get(task_id)
    if not task:
        print(f"DEBUG Error: Task {task_id} not found in database.")
        raise HTTPException(status_code=404, detail=f"Task {task_id} not found")
        
    if task.description and "Practice:" in task.title:
        return task

    student = await Student.get(task.student_id)
    if not student:
        print(f"DEBUG Error: Student {task.student_id} not found for task {task_id}")
        raise HTTPException(status_code=404, detail="Student not found")

    # Resilience: Try to find course by ID in CSV, or fallback to Progress record
    course_name = "Global"
    matched_course = None
    for c in csv_manager.get_courses():
        if str(c.get('id')) == str(task.course_id):
            matched_course = c
            course_name = c['name']
            break
    
    if not matched_course:
        print(f"DEBUG Warning: Task {task_id} has course_id {task.course_id} which wasn't found in CSV. Checking Progress...")
        # Fallback to Progress record to get the course name
        from models import Progress
        progress = await Progress.find_one(
            Progress.student_id == task.student_id,
            Progress.course_id == task.course_id
        )
        if progress and progress.course_name:
            course_name = progress.course_name
            print(f"DEBUG: Found course name '{course_name}' from Progress record.")
        else:
            print(f"DEBUG Error: Could not determine course name for task {task_id}.")
            course_name = "General Academic Subject"

    print(f"DEBUG: Calling AI to generate task content for topic: {task.title} in course: {course_name}")
    # Call AI service to generate a real task
    try:
        # Import to be safe if not at top
        from services.ai_service import ai_service
        ai_task = await ai_service.generate_personalized_task(
            student.dict(), 
            course_name, 
            task.title
        )
        
        task.title = ai_task.get("title", task.title)
        task.description = ai_task.get("description", task.description)
        task.type = ai_task.get("type", task.type)
        
        await task.save()
        print(f"DEBUG: Task {task_id} successfully updated with AI content.")
        return task
    except Exception as e:
        print(f"DEBUG Error: AI Generation failed: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"AI content generation failed: {str(e)}")

async def generate_tasks_for_student(student_id: str, course_id: str):
    # course = await Course.get(course_id)
    course = None
    for c in csv_manager.get_courses():
        if str(c['id']) == str(course_id):
            course = c
            break

    if not course:
        return
    
    # Create a task for each topic
    for topic in course.get('topics', []):
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
                description=f"Learn and master the concepts of {topic} in {course['name']}.",
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

@router.get("/fyp/details/{project_id}")
async def get_fyp_details(project_id: str):
    project = csv_manager.get_fyp_project_by_id(project_id)
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    
    details = await ai_service.generate_project_details(project['title'], project['description'])
    return details

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

@router.get("/students/{student_id}/roadmap")
async def get_student_roadmap(student_id: str, interest: Optional[str] = None):
    student = await Student.get(student_id)
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    target_interest = interest
    if not target_interest:
        if student.interests:
            target_interest = student.interests[0]
        else:
            target_interest = "Computer Science General"
            
    # Check if roadmap exists in DB
    existing_roadmap = await StudentRoadmap.find_one(
        StudentRoadmap.student_id == student_id,
        StudentRoadmap.interest == target_interest
    )
    
    if existing_roadmap:
        return existing_roadmap.dict()

    # Generate new roadmap via AI
    roadmap_json = await ai_service.generate_interest_roadmap(student.dict(), target_interest)
    
    # Convert JSON to Model
    phases = []
    for p_data in roadmap_json.get("phases", []):
        # Extract topics safely: could be strings or objects
        raw_topics = p_data.get("topics", [])
        topics = []
        for t in raw_topics:
            if isinstance(t, str):
                topics.append(RoadmapTopic(title=t))
            elif isinstance(t, dict):
                topics.append(RoadmapTopic(
                    title=t.get("title", "Topic"),
                    status=t.get("status", "pending"),
                    resources=t.get("resources", [])
                ))
                
        phases.append(RoadmapPhase(
            title=p_data.get("title", "Phase"),
            topics=topics,
            project=p_data.get("project"),
            duration=p_data.get("duration")
        ))
        
    new_roadmap = StudentRoadmap(
        student_id=student_id,
        interest=target_interest,
        phases=phases,
        resources=roadmap_json.get("resources", []) # Map global resources
    )
    await new_roadmap.insert()
    
    return new_roadmap.dict()

@router.post("/students/{student_id}/roadmap/update")
async def update_roadmap_progress(
    student_id: str, 
    interest: str, 
    phase_index: int, 
    topic_index: int, 
    update_data: RoadmapStatusUpdate
):
    roadmap = await StudentRoadmap.find_one(
        StudentRoadmap.student_id == student_id,
        StudentRoadmap.interest == interest
    )
    if not roadmap:
        raise HTTPException(status_code=404, detail="Roadmap not found")
        
    if 0 <= phase_index < len(roadmap.phases):
        phase = roadmap.phases[phase_index]
        if 0 <= topic_index < len(phase.topics):
            phase.topics[topic_index].status = update_data.status
            await roadmap.save()
            return {"status": "success", "message": "Topic updated"}
            
    raise HTTPException(status_code=400, detail="Invalid phase or topic index")

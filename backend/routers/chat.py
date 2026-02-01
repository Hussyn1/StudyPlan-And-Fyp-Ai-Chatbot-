from fastapi import APIRouter, HTTPException
from models import ChatSession, ChatMessage, Student, Task, Progress, Course, StudentRoadmap
from services.ai_service import ai_service
from typing import List
from pydantic import BaseModel

router = APIRouter()

class ChatRequest(BaseModel):
    student_id: str
    message: str

@router.post("/chat")
async def chat(request: ChatRequest):
    student = await Student.get(request.student_id)
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    # Find or create session (simplified)
    # In a real app, we might want to manage session IDs more explicitly
    session = await ChatSession.find_one(ChatSession.student_id == request.student_id)
    if not session:
        session = ChatSession(student_id=request.student_id)
        await session.insert()
    
    # Add user message
    user_msg = ChatMessage(role="user", content=request.message)
    session.messages.append(user_msg)
    
    # Get student tasks for context
    tasks = await Task.find(Task.student_id == request.student_id).to_list()
    tasks_context = []
    for t in tasks[-5:]: # Only recent 5 tasks for token limit
        tasks_context.append({
            "title": t.title,
            "status": t.status,
            "verified": t.verified,
            "feedback": t.ai_feedback,
            "submission": t.submission
        })

    # Get student courses (progress) for context
    progress_records = await Progress.find(Progress.student_id == request.student_id).to_list()
    courses_context = []
    for p in progress_records:
        courses_context.append({
            "course_name": p.course_name,
            "progress": f"{p.tasks_completed}/{p.total_tasks}",
            "grade": p.grade
        })

    # Get Active Roadmap Context
    roadmap_context = None
    if student.interests:
        # Try to find roadmap for primary interest
        active_roadmap = await StudentRoadmap.find_one(
            StudentRoadmap.student_id == request.student_id, 
            StudentRoadmap.interest == student.interests[0]
        )
        if active_roadmap:
            # Create a summary of current progress
            current_phase = active_roadmap.phases[active_roadmap.current_phase_index]
            pending_topics = [t.title for t in current_phase.topics if t.status != "completed"]
            
            roadmap_context = {
                "interest": active_roadmap.interest,
                "current_phase": current_phase.title,
                "project_goal": current_phase.project,
                "pending_topics": pending_topics,
                "completed_phases": active_roadmap.current_phase_index
            }

    # Get AI response
    context = [{"role": m.role, "content": m.content} for m in session.messages[-10:]]
    try:
        ai_response_text = await ai_service.get_chat_response(
            request.message, 
            context, 
            student_profile=student.dict(),
            tasks_context=tasks_context,
            courses_context=courses_context,
            roadmap_context=roadmap_context
        )
        
        if ai_response_text.startswith("Error:"):
            # Handle AI service errors without crashing
             return {"response": f"I'm sorry, I'm having trouble connecting to my brain right now. {ai_response_text}", "is_error": True}

        # Check for Tool Call (JSON)
        import json
        if "```json" in ai_response_text and "create_task" in ai_response_text:
            try:
                # Extract JSON
                json_str = ai_response_text.split("```json")[1].split("```")[0].strip()
                tool_cmd = json.loads(json_str)
                
                if tool_cmd.get("tool") == "create_task":
                    topic = tool_cmd.get("topic")
                    course_name = tool_cmd.get("course")
                    
                    # Logic to find course ID from name (fuzzy matching or use generic)
                    # For now, we try to find a matching course in the student's progress
                    target_course_id = None
                    for p in progress_records:
                        if course_name and course_name.lower() in (p.course_name or "").lower():
                            target_course_id = p.course_id
                            break
                    
                    # Fallback to first course if not found
                    if not target_course_id and progress_records:
                        target_course_id = progress_records[0].course_id
                        
                    if target_course_id:
                         # Generate task
                        ai_task = await ai_service.generate_personalized_task(
                            student.dict(), 
                            course_name or "General", 
                            topic
                        )
                        
                        new_task = Task(
                            student_id=request.student_id,
                            course_id=target_course_id,
                            title=ai_task.get("title", f"Practice {topic}"),
                            description=ai_task.get("description", "Generated practice task."),
                            type=ai_task.get("type", "theory"),
                            difficulty="medium",
                            status="pending"
                        )
                        await new_task.insert()

                        # Update Progress: Increment total_tasks
                        try:
                            progress_doc = await Progress.find_one(
                                Progress.student_id == request.student_id, 
                                Progress.course_id == target_course_id
                            )
                            if progress_doc:
                                progress_doc.total_tasks += 1
                                # Recalculate accuracy if needed, though simpler to just update total
                                current_completed = progress_doc.tasks_completed
                                progress_doc.accuracy = current_completed / progress_doc.total_tasks
                                await progress_doc.save()
                        except Exception as prog_e:
                            print(f"Error updating progress count: {prog_e}")
                        
                        # Replace the JSON response with a natural language confirmation
                        ai_response_text = f"I've generated a new practice task for you on **{topic}**. You can find it in your Task Dashboard! (Reason: {tool_cmd.get('reason', 'Practice makes perfect')})"
            except Exception as e:
                print(f"Tool execution error: {e}")
                # Fallback: Just return the text (maybe cleaned) or generic message
                ai_response_text = "I tried to generate a task but something went wrong. Please try again."

    except Exception as e:
        print(f"Error in chat endpoint: {e}")
        return {"response": "I encountered an unexpected error while thinking. Please try again.", "is_error": True}
    
    # Add AI message
    ai_msg = ChatMessage(role="model", content=ai_response_text)
    session.messages.append(ai_msg)
    await session.save()
    
    return {"response": ai_response_text, "is_error": False}

class GenerateTaskRequest(BaseModel):
    student_id: str
    topic: str
    course_id: str

@router.post("/chat/generate-task")
async def generate_chat_task(request: GenerateTaskRequest):
    student = await Student.get(request.student_id)
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
        
    course = await Course.get(request.course_id)
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")

    # Generate task
    ai_task = await ai_service.generate_personalized_task(
        student.dict(), 
        course.name, 
        request.topic
    )
    
    # Save to DB
    new_task = Task(
        student_id=request.student_id,
        course_id=request.course_id,
        title=ai_task.get("title", f"Practice {request.topic}"),
        description=ai_task.get("description", "Generated practice task."),
        type=ai_task.get("type", "theory"),
        difficulty="medium",
        status="pending"
    )
    await new_task.insert()
    
    return {"status": "success", "task": new_task, "message": "New practice task generated!"}

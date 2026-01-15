from fastapi import APIRouter, HTTPException
from models import ChatSession, ChatMessage, Student
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
    
    # Get AI response
    # Context could just be recent messages
    context = [{"role": m.role, "content": m.content} for m in session.messages[-10:]]
    ai_response_text = await ai_service.get_chat_response(request.message, context, student_profile=student.dict())
    
    # Add AI message
    ai_msg = ChatMessage(role="model", content=ai_response_text)
    session.messages.append(ai_msg)
    await session.save()
    
    return {"response": ai_response_text}

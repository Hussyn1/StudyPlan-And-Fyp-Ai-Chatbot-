from fastapi import APIRouter, HTTPException
from models import Student
from pydantic import BaseModel

router = APIRouter()

class LoginRequest(BaseModel):
    roll_number: str
    password: str

@router.post("/login")
async def login(request: LoginRequest):
    # Find student by roll number
    student = await Student.find_one(Student.roll_number == request.roll_number)
    
    if not student:
        raise HTTPException(status_code=401, detail="Invalid roll number or password")
    
    # Check password (in real app, use hashing like bcrypt)
    if student.password != request.password:
        raise HTTPException(status_code=401, detail="Invalid roll number or password")
    
    return {
        "status": "success",
        "message": "Login successful",
        "student_id": str(student.id),
        "name": student.name
    }

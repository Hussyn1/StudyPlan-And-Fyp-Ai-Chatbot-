from fastapi import APIRouter
from models import Course
from typing import List

router = APIRouter()

@router.get("/courses", response_model=List[Course])
async def get_courses():
    courses = await Course.find_all().to_list()
    return courses

@router.post("/courses")
async def create_course(course: Course):
    await course.insert()
    return course

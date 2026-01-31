import asyncio
import sys
import os

# Add backend to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from utils.csv_manager import csv_manager
from services.ml_service import ml_service
from services.ai_service import ai_service
from database import init_db
from models import Student

async def test_all():
    print("--- 1. Testing CSV Manager ---")
    fyps = csv_manager.get_fyp_projects()
    print(f"FYPs: {len(fyps)}")
    courses = csv_manager.get_courses()
    print(f"Courses: {len(courses)}")
    students = csv_manager.get_students()
    print(f"Students: {len(students)}")
    
    if len(fyps) > 0:
        print(f"Sample FYP: {fyps[0]['title']}")
    if len(courses) > 0:
        print(f"Sample Course: {courses[0]['name']}")
    if len(students) > 0:
        print(f"Sample Student: {students[0]['name']}")

    print("\n--- 2. Testing Seeding (Mock) ---")
    # We won't actually connect to Mongo in this fast test unless we have credentials, 
    # but we can try if local mongo is running.
    # Assuming local mongo is running...
    try:
        await init_db()
        from seed_mongo import seed_initial_data
        await seed_initial_data()
        
        # Verify student inserted
        count = await Student.find_all().count()
        print(f"Total Students in DB: {count}")
    except Exception as e:
        print(f"Skipping DB test: {e}")

    print("\n--- 3. Testing ML Service (FYP Recommendations) ---")
    # We need a student ID. If DB test failed, we can't do this fully, 
    # but we can check if the function logic runs if we mock the student.
    # For now, let's skip full ML service test if DB is not active.
    
    print("\n--- 4. Testing AI Service (Interest Roadmap) ---")
    # This calls Ollama, so it requires Ollama running.
    # We will try it.
    try:
        roadmap = await ai_service.generate_interest_roadmap(
            {"name": "Test User", "current_semester": 6, "learning_style": "Visual", "study_pace": "Fast"}, 
            "Web Development"
        )
        print("Roadmap generated successfully.")
        print(roadmap.get("interest"))
    except Exception as e:
        print(f"AI Service failed (expected if no Ollama): {e}")

if __name__ == "__main__":
    asyncio.run(test_all())

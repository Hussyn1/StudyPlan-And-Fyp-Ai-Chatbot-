import asyncio
import sys
import os

# Add backend to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from motor.motor_asyncio import AsyncIOMotorClient
from beanie import init_beanie
from models import Course, FYPProject, Student, Task, Progress, ChatSession
from dotenv import load_dotenv

load_dotenv()


async def seed_initial_data():
    print("Checking if data seeding is required...")
    
    
    # Seed Students from CSV
    from utils.csv_manager import csv_manager
    students = csv_manager.get_students()
    
    for s_data in students:
        # Check if student exists
        exists = await Student.find_one(Student.roll_number == s_data["roll_number"])
        if not exists:
            # Create new student
            # CSV data is already dict, but we need to ensure types match Model
            # fields like interests are list in model, list in CSV dict (handled by manager)
            
            student = Student(**s_data)
            await student.insert()
            print(f"Inserted Student: {s_data['name']} ({s_data['roll_number']})")
            print(f"Student already exists: {s_data['name']}")

    print("[DONE] Student seeding completed.")
    print("[INFO] Courses and FYP Projects are now served directly from CSVs.")

if __name__ == "__main__":
    asyncio.run(seed_initial_data())

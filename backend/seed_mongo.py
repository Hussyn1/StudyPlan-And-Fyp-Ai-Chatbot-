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
    
    
    # fast check: if we have students, assume seeded to prevent startup timeout
    if await Student.count() > 0:
        print("[INFO] Students already exist in database. Skipping CSV seeding to speed up startup.")
        print("To force re-seed, clear the database or run seed script manually.")
        return

    # Seed Students from CSV
    from utils.csv_manager import csv_manager
    students = csv_manager.get_students()
    
    # Batch insert would be better, but keeping loop for safety for now, just optimizing the check
    print(f"Seeding {len(students)} students from CSV...")
    for s_data in students:
        # Check if student exists
        exists = await Student.find_one(Student.roll_number == s_data["roll_number"])
        if not exists:
            student = Student(**s_data)
            await student.insert()
            print(f"Inserted: {s_data['name']}")
        else:
            print(f"Skipping: {s_data['name']}")

    print("[DONE] Student seeding completed.")
    print("[INFO] Courses and FYP Projects are now served directly from CSVs.")

if __name__ == "__main__":
    asyncio.run(seed_initial_data())

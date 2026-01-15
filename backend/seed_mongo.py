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


async def seed_data():
    # Initialize database connection
    uri = os.getenv("MONGODB_URI", "mongodb://localhost:27017")
    print(f"Connecting to: {uri[:20]}...")
    client = AsyncIOMotorClient(uri)
    
    await init_beanie(database=client.ai_chatbot_db, document_models=[
        Student, Course, Task, Progress, ChatSession, FYPProject
    ])
    
    print("Connected to MongoDB!")
    
    # 1. Seed Courses
    courses_data = [
        # Semester 1
        {"code": "CS101", "name": "Programming Fundamentals", "semester": 1, "topics": ["Variables & Data Types", "Control Structures", "Loops", "Functions", "Arrays"]},
        {"code": "CS102", "name": "Digital Logic Design", "semester": 1, "topics": ["Number Systems", "Logic Gates", "Boolean Algebra", "Combinational Circuits", "Sequential Circuits"]},
        {"code": "MATH101", "name": "Calculus I", "semester": 1, "topics": ["Limits", "Derivatives", "Integrals", "Applications of Integrals", "Infinite Series"]},
        {"code": "ENG101", "name": "English Composition", "semester": 1, "topics": ["Grammar", "Sentence Structure", "Essay Writing", "Research Skills", "Citation"]},
        
        # Semester 2
        {"code": "CS201", "name": "Object Oriented Programming", "semester": 2, "topics": ["Classes & Objects", "Inheritance", "Polymorphism", "Encapsulation", "Exception Handling"]},
        {"code": "CS202", "name": "Discrete Mathematics", "semester": 2, "topics": ["Set Theory", "Propositional Logic", "Graph Theory", "Combinatorics", "Number Theory"]},
        
        # Semester 3
        {"code": "CS301", "name": "Data Structures", "semester": 3, "topics": ["Linked Lists", "Stacks & Queues", "Trees", "Graphs", "Hashing"]},
        {"code": "CS303", "name": "Database Systems", "semester": 3, "topics": ["ER Models", "SQL", "Normalization", "Indexing", "Transactions"]},
        
        # Higher semesters
        {"code": "CS601", "name": "Machine Learning", "semester": 6, "topics": ["Linear Regression", "Logistic Regression", "Decision Trees", "Neural Networks", "Clustering"]},
        {"code": "CS603", "name": "Mobile Development", "semester": 6, "topics": ["Flutter Basics", "Widgets", "State Management", "Local Data", "External APIs"]},
    ]
    
    for c_data in courses_data:
        exists = await Course.find_one(Course.code == c_data["code"])
        if not exists:
            # Use provided topics or default
            if "topics" not in c_data:
                c_data["topics"] = ["Topic 1", "Topic 2", "Topic 3", "Topic 4", "Topic 5"]
            await Course(**c_data).insert()
            print(f"Inserted Course: {c_data['name']}")
        else:
            # Always update topics if provided in the list
            if "topics" in c_data:
                exists.topics = c_data["topics"]
                await exists.save()
                print(f"Updated Course Topics: {exists.name}")
            elif not exists.topics:
                exists.topics = ["Topic 1", "Topic 2", "Topic 3", "Topic 4", "Topic 5"]
                await exists.save()
                print(f"Defaulted Course Topics: {exists.name}")

    # 2. Seed FYP Projects
    fyp_data = [
        {
            "title": "Student Performance Prediction",
            "description": "Predict grades using ML.",
            "category": "AI/ML",
            "complexity": "Medium",
            "required_skills": ["Machine Learning", "Python"],
            "trending": True
        },
        {
            "title": "E-Commerce Website",
            "description": "Full stack online store.",
            "category": "Web",
            "complexity": "Medium",
            "required_skills": ["Web Development", "React"],
            "trending": False
        },
        {
            "title": "Blockchain Voting",
            "description": "Secure voting system.",
            "category": "Security",
            "complexity": "Hard",
            "required_skills": ["Blockchain", "Security"],
            "trending": True
        }
    ]
    
    for f_data in fyp_data:
        exists = await FYPProject.find_one(FYPProject.title == f_data["title"])
        if not exists:
            await FYPProject(**f_data).insert()
            print(f"Inserted Project: {f_data['title']}")

if __name__ == "__main__":
    asyncio.run(seed_data())

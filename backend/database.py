from motor.motor_asyncio import AsyncIOMotorClient
from beanie import init_beanie
from models import Student, Course, Task, Progress, ChatSession, FYPProject
import os
from dotenv import load_dotenv

load_dotenv()

async def init_db():
    # Retrieve the connection string from environment variable or use default local
    uri = os.getenv("MONGODB_URI", "mongodb://localhost:27017")
    client = AsyncIOMotorClient(uri)
    
    # Initialize Beanie with the database and document models
    await init_beanie(database=client.ai_chatbot_db, document_models=[
        Student,
        Course,
        Task,
        Progress,
        ChatSession,
        FYPProject
    ])
from motor.motor_asyncio import AsyncIOMotorClient
from beanie import init_beanie
from models import Student, Course, Task, Progress, FYPProject, ChatSession, StudentRoadmap
import os
import certifi
from dotenv import load_dotenv

load_dotenv(override=True)

async def init_db():
    # Retrieve the connection string from environment variable or use default local
    uri = os.getenv("MONGODB_URI", "mongodb://localhost:27017")
    print(f"DEBUG: Connecting to MongoDB with URI starting with: {uri[:20]}...")
    
    # Try connecting with relaxed SSL for diagnostics
    # Also added serverSelectionTimeoutMS to fail faster if there's a network issue
    client = AsyncIOMotorClient(
        uri, 
        tlsCAFile=certifi.where(),
        tlsAllowInvalidCertificates=True, # Diagnostic: allows identifying if it's a cert verify issue
        serverSelectionTimeoutMS=5000
    )
    
    try:
        # Check connection
        await client.admin.command('ping')
        print("Successfully connected to MongoDB Atlas")
        
        # Initialize Beanie
        await init_beanie(database=client.ai_chatbot_db, document_models=[
            Student,
            Course,
            Task,
            Progress,
            ChatSession,
            FYPProject,
            StudentRoadmap
        ])
    except Exception as e:
        print(f"Failed to connect to MongoDB: {e}")
        # If it fails, try without SRV if possible or fallback to local
        if "mongodb+srv" in uri:
            print("Troubleshooting Tip: Try using the standard connection string (mongodb://) instead of srv, or check your firewall/ISP.")
        raise e
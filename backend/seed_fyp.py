import asyncio
import sys
import os
import random

# Add backend to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__))) or sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))

from motor.motor_asyncio import AsyncIOMotorClient
from beanie import init_beanie
from models import FYPProject, Student, Course, Task, Progress, ChatSession
from dotenv import load_dotenv

load_dotenv()

DOMAINS = [
    "Healthcare", "Education", "FinTech", "Agriculture", "Smart Cities", 
    "Social Media", "Environment", "Transportation", "Retail", "Cybersecurity", 
    "Energy", "Manufacturing", "Entertainment", "Sports", "Real Estate",
    "Logistics", "Hospitality", "Automotive", "E-Governance", "Legal"
]

TECHNOLOGIES = [
    "AI/ML", "Blockchain", "IoT", "Flutter", "React Native", "Next.js", 
    "Cybersecurity", "VR/AR", "Data Science", "Bioinformatics", "Robotics",
    "Cloud Computing", "NLP", "Computer Vision", "Deep Learning", "Edge Computing"
]

TYPES = [
    "Management System", "Predictive Analytics", "Real-time Monitoring", 
    "Recommendation Engine", "Marketplace", "Security Framework", 
    "Diagnostic Tool", "Immersive Simulation", "Automation Platform",
    "Fraud Detection", "Optimization Tool", "Decision Support System"
]

ADJECTIVES = ["Smart", "Intelligent", "Autonomous", "Secure", "Cloud-Native", "Decentralized", "Scalable", "Robust"]

def generate_ideas(count=500):
    ideas = []
    seen_titles = set()
    
    while len(ideas) < count:
        adj = random.choice(ADJECTIVES)
        domain = random.choice(DOMAINS)
        tech = random.choice(TECHNOLOGIES)
        ptype = random.choice(TYPES)
        
        # Possible patterns
        patterns = [
            f"{adj} {ptype} for {domain} using {tech}",
            f"{tech}-Based {adj} {domain} {ptype}",
            f"{adj} {domain} {ptype} with {tech}",
            f"{domain} {ptype}: An {adj} {tech} Approach"
        ]
        
        title = random.choice(patterns)
        if title in seen_titles:
            continue
            
        seen_titles.add(title)
        
        complexity = random.choice(["Medium", "Hard"])
        # Skills usually relate to tech and domain
        skills = [tech]
        if tech in ["AI/ML", "Data Science", "Deep Learning"]:
            skills.append("Python")
        if tech in ["Flutter", "React Native"]:
            skills.append("Mobile Development")
        if tech in ["Blockchain"]:
            skills.append("Solidity")
        if tech in ["Next.js"]:
            skills.append("Web Development")
            
        description = f"Developing an {title.lower()} to solve critical challenges in the {domain} sector. This project focuses on high performance and reliability using {tech}."
        
        ideas.append({
            "title": title,
            "description": description,
            "category": domain,
            "complexity": complexity,
            "required_skills": skills,
            "trending": random.choice([True, False])
        })
        
    return ideas

async def seed_fyp():
    uri = os.getenv("MONGODB_URI", "mongodb://localhost:27017")
    print(f"Connecting to MongoDB...")
    client = AsyncIOMotorClient(uri)
    
    await init_beanie(database=client.ai_chatbot_db, document_models=[
        FYPProject, Student, Course, Task, Progress, ChatSession
    ])
    
    print("Generating 500 project ideas...")
    ideas = generate_ideas(500)
    
    print("Inserting into database...")
    batch_size = 50
    for i in range(0, len(ideas), batch_size):
        batch = ideas[i:i + batch_size]
        # Skip if title exists
        to_insert = []
        for idea in batch:
            exists = await FYPProject.find_one(FYPProject.title == idea["title"])
            if not exists:
                to_insert.append(FYPProject(**idea))
        
        if to_insert:
            await FYPProject.insert_many(to_insert)
            print(f"Inserted batch {i//batch_size + 1}")

    print(f"Done! Successfully seeded database with more projects.")

if __name__ == "__main__":
    asyncio.run(seed_fyp())

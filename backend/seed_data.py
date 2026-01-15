# seed_data.py - Populate database with sample CS curriculum data
import json
from database import SessionLocal, init_db
from models import Course, Task, FYPProject

def seed_courses():
    """Seed CS courses for semesters 1-8"""
    db = SessionLocal()
    
    courses_data = [
        # Semester 1
        {"code": "CS101", "name": "Programming Fundamentals", "semester": 1, "credits": 3, "prerequisites": None},
        {"code": "CS102", "name": "Digital Logic Design", "semester": 1, "credits": 3, "prerequisites": None},
        {"code": "MATH101", "name": "Calculus I", "semester": 1, "credits": 3, "prerequisites": None},
        {"code": "ENG101", "name": "English Composition", "semester": 1, "credits": 3, "prerequisites": None},
        
        # Semester 2
        {"code": "CS201", "name": "Object Oriented Programming", "semester": 2, "credits": 3, "prerequisites": json.dumps([1])},
        {"code": "CS202", "name": "Discrete Mathematics", "semester": 2, "credits": 3, "prerequisites": None},
        {"code": "MATH201", "name": "Linear Algebra", "semester": 2, "credits": 3, "prerequisites": json.dumps([3])},
        {"code": "PHY101", "name": "Physics", "semester": 2, "credits": 3, "prerequisites": None},
        
        # Semester 3
        {"code": "CS301", "name": "Data Structures", "semester": 3, "credits": 4, "prerequisites": json.dumps([1, 5])},
        {"code": "CS302", "name": "Computer Organization", "semester": 3, "credits": 3, "prerequisites": json.dumps([2])},
        {"code": "CS303", "name": "Database Systems", "semester": 3, "credits": 3, "prerequisites": json.dumps([1])},
        {"code": "MATH301", "name": "Probability & Statistics", "semester": 3, "credits": 3, "prerequisites": json.dumps([3])},
        
        # Semester 4
        {"code": "CS401", "name": "Algorithms", "semester": 4, "credits": 4, "prerequisites": json.dumps([9])},
        {"code": "CS402", "name": "Operating Systems", "semester": 4, "credits": 3, "prerequisites": json.dumps([9, 10])},
        {"code": "CS403", "name": "Computer Networks", "semester": 4, "credits": 3, "prerequisites": None},
        {"code": "CS404", "name": "Software Engineering", "semester": 4, "credits": 3, "prerequisites": json.dumps([5])},
        
        # Semester 5
        {"code": "CS501", "name": "Artificial Intelligence", "semester": 5, "credits": 3, "prerequisites": json.dumps([13])},
        {"code": "CS502", "name": "Web Technologies", "semester": 5, "credits": 3, "prerequisites": json.dumps([11])},
        {"code": "CS503", "name": "Computer Graphics", "semester": 5, "credits": 3, "prerequisites": json.dumps([7])},
        {"code": "CS504", "name": "Theory of Computation", "semester": 5, "credits": 3, "prerequisites": json.dumps([6])},
        
        # Semester 6
        {"code": "CS601", "name": "Machine Learning", "semester": 6, "credits": 3, "prerequisites": json.dumps([17, 12])},
        {"code": "CS602", "name": "Information Security", "semester": 6, "credits": 3, "prerequisites": json.dumps([15])},
        {"code": "CS603", "name": "Mobile Application Development", "semester": 6, "credits": 3, "prerequisites": json.dumps([5])},
        {"code": "CS604", "name": "Compiler Construction", "semester": 6, "credits": 3, "prerequisites": json.dumps([20])},
        
        # Semester 7
        {"code": "CS701", "name": "Deep Learning", "semester": 7, "credits": 3, "prerequisites": json.dumps([21])},
        {"code": "CS702", "name": "Cloud Computing", "semester": 7, "credits": 3, "prerequisites": json.dumps([15])},
        {"code": "CS703", "name": "Natural Language Processing", "semester": 7, "credits": 3, "prerequisites": json.dumps([21])},
        
        # Semester 8
        {"code": "CS801", "name": "FYP-I", "semester": 8, "credits": 6, "prerequisites": None},
    ]
    
    for course_data in courses_data:
        existing = db.query(Course).filter(Course.code == course_data["code"]).first()
        if not existing:
            course = Course(**course_data)
            db.add(course)
    
    db.commit()
    print(f"✅ Seeded {len(courses_data)} courses")
    db.close()

def seed_tasks():
    """Seed sample tasks for each course"""
    db = SessionLocal()
    
    # Get all courses
    courses = db.query(Course).all()
    
    task_templates = {
        "Programming Fundamentals": [
            {"title": "Variables and Data Types", "description": "Write a program to demonstrate different data types", "difficulty": 1, "topic": "Basics", "task_type": "coding", "points": 10},
            {"title": "Loops Practice", "description": "Solve 5 problems using loops", "difficulty": 2, "topic": "Loops", "task_type": "coding", "points": 15},
            {"title": "Functions", "description": "Create reusable functions for common operations", "difficulty": 3, "topic": "Functions", "task_type": "coding", "points": 20},
        ],
        "Data Structures": [
            {"title": "Linked List Implementation", "description": "Implement a singly linked list with basic operations", "difficulty": 3, "topic": "Linked Lists", "task_type": "coding", "points": 25},
            {"title": "Binary Search Tree", "description": "Build a BST with insert, search, delete operations", "difficulty": 4, "topic": "Trees", "task_type": "coding", "points": 30},
            {"title": "Stack Applications", "description": "Solve expression evaluation using stacks", "difficulty": 2, "topic": "Stacks", "task_type": "coding", "points": 20},
        ],
        "Algorithms": [
            {"title": "Sorting Algorithms", "description": "Implement QuickSort and MergeSort", "difficulty": 3, "topic": "Sorting", "task_type": "coding", "points": 25},
            {"title": "Graph Traversal", "description": "Implement BFS and DFS", "difficulty": 4, "topic": "Graphs", "task_type": "coding", "points": 30},
            {"title": "Dynamic Programming", "description": "Solve Fibonacci using DP", "difficulty": 5, "topic": "DP", "task_type": "coding", "points": 35},
        ],
        "Machine Learning": [
            {"title": "Linear Regression", "description": "Build a linear regression model from scratch", "difficulty": 3, "topic": "Regression", "task_type": "coding", "points": 25},
            {"title": "Classification with KNN", "description": "Implement K-Nearest Neighbors classifier", "difficulty": 3, "topic": "Classification", "task_type": "coding", "points": 25},
            {"title": "Neural Network Basics", "description": "Create a simple neural network", "difficulty": 5, "topic": "Neural Networks", "task_type": "coding", "points": 40},
        ],
    }
    
    task_count = 0
    for course in courses:
        if course.name in task_templates:
            for task_data in task_templates[course.name]:
                task_data["course_id"] = course.id
                existing = db.query(Task).filter(
                    Task.course_id == course.id,
                    Task.title == task_data["title"]
                ).first()
                
                if not existing:
                    task = Task(**task_data)
                    db.add(task)
                    task_count += 1
    
    db.commit()
    print(f"✅ Seeded {task_count} tasks")
    db.close()

def seed_fyp_projects():
    """Seed FYP project ideas"""
    db = SessionLocal()
    
    fyp_data = [
        {
            "title": "Student Performance Prediction using Machine Learning",
            "description": "Build an ML model to predict student performance based on historical data",
            "complexity": "intermediate",
            "required_skills": json.dumps(["Machine Learning", "Python", "Data Analysis", "Database"]),
            "category": "AI/ML",
            "trending": True,
            "preparation_months": 2
        },
        {
            "title": "E-Learning Recommendation System",
            "description": "Develop a personalized course recommendation system",
            "complexity": "intermediate",
            "required_skills": json.dumps(["Machine Learning", "Web Development", "Database"]),
            "category": "AI/ML",
            "trending": True,
            "preparation_months": 3
        },
        {
            "title": "Real-time Object Detection System",
            "description": "Create a computer vision system for object detection",
            "complexity": "advanced",
            "required_skills": json.dumps(["Deep Learning", "Computer Vision", "Python"]),
            "category": "AI/ML",
            "trending": True,
            "preparation_months": 4
        },
        {
            "title": "Hospital Management System",
            "description": "Complete web-based hospital management solution",
            "complexity": "beginner",
            "required_skills": json.dumps(["Web Development", "Database", "OOP"]),
            "category": "Web",
            "trending": False,
            "preparation_months": 2
        },
        {
            "title": "Blockchain-based Voting System",
            "description": "Secure electronic voting using blockchain",
            "complexity": "advanced",
            "required_skills": json.dumps(["Blockchain", "Security", "Web Development"]),
            "category": "Security",
            "trending": True,
            "preparation_months": 4
        },
        {
            "title": "Chatbot for Customer Support",
            "description": "NLP-based chatbot for automated customer service",
            "complexity": "intermediate",
            "required_skills": json.dumps(["NLP", "Machine Learning", "Web Development"]),
            "category": "AI/ML",
            "trending": True,
            "preparation_months": 3
        },
        {
            "title": "Mobile Expense Tracker",
            "description": "Cross-platform mobile app for expense management",
            "complexity": "beginner",
            "required_skills": json.dumps(["Mobile Development", "Database", "UI/UX"]),
            "category": "Mobile",
            "trending": False,
            "preparation_months": 2
        },
        {
            "title": "Social Media Sentiment Analysis",
            "description": "Analyze sentiment of social media posts using NLP",
            "complexity": "intermediate",
            "required_skills": json.dumps(["NLP", "Machine Learning", "Data Analysis"]),
            "category": "AI/ML",
            "trending": True,
            "preparation_months": 3
        },
    ]
    
    for project_data in fyp_data:
        existing = db.query(FYPProject).filter(FYPProject.title == project_data["title"]).first()
        if not existing:
            project = FYPProject(**project_data)
            db.add(project)
    
    db.commit()
    print(f"✅ Seeded {len(fyp_data)} FYP projects")
    db.close()

if __name__ == "__main__":
    print("Initializing database...")
    init_db()
    print("✅ Database initialized")
    
    print("\nSeeding data...")
    seed_courses()
    seed_tasks()
    seed_fyp_projects()
    
    print("\n🎉 All done! Database is ready to use.")
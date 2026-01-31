import csv
import random
import os

# Configuration
NUM_FYP = 650
NUM_STUDENTS = 1000

# Paths
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(BASE_DIR, "data")

# Data Pools
CATEGORIES = ["AI/ML", "Web", "Mobile", "Security", "Blockchain", "IoT", "Cloud", "Data Science", "AR/VR", "Game Dev"]
SKILLS = {
    "AI/ML": ["Python", "TensorFlow", "PyTorch", "Scikit-learn", "NLP", "OpenCV"],
    "Web": ["React", "Node.js", "Django", "Vue.js", "PostgreSQL", "MongoDB"],
    "Mobile": ["Flutter", "React Native", "Swift", "Kotlin", "Firebase"],
    "Security": ["Cryptography", "Network Security", "Ethical Hacking", "Python", "Linux"],
    "Blockchain": ["Solidity", "Ethereum", "Smart Contracts", "Web3.js"],
    "IoT": ["Arduino", "Raspberry Pi", "C++", "Sensors", "MQTT"],
    "Cloud": ["AWS", "Azure", "Docker", "Kubernetes", "DevOps"],
    "Data Science": ["Pandas", "NumPy", "Matplotlib", "SQL", "R"],
    "AR/VR": ["Unity", "C#", "ARKit", "Blender"],
    "Game Dev": ["Unity", "Unreal Engine", "C++", "C#"]
}
TITLES_PREFIX = ["Advanced", "Smart", "Intelligent", "Automated", "Decentralized", "Secure", "Real-time", "Next-Gen"]
TITLES_SUFFIX = ["System", "Platform", "Application", "Tool", "Module", "Assistant", "Tracker", "Analyzer"]

NAMES_FIRST = ["Ali", "Sara", "Ahmed", "Fatima", "Bilal", "Zainab", "Omar", "Ayesha", "Usman", "Hina", "Saad", "Maria"]
NAMES_LAST = ["Khan", "Ahmed", "Raza", "Shah", "Malik", "Hussain", "Iqbal", "Butt", "Sheikh", "Mirza"]
UNIVERSITIES = ["FAST NUCES", "NUST", "LUMS", "COMSATS", "UET", "PU", "IBA"]

def generate_fyp_data():
    data = []
    print(f"Generating {NUM_FYP} FYP projects...")
    for i in range(1, NUM_FYP + 1):
        category = random.choice(CATEGORIES)
        skills = random.sample(SKILLS[category], k=random.randint(2, 4))
        
        title = f"{random.choice(TITLES_PREFIX)} {category} {random.choice(TITLES_SUFFIX)}"
        # Add some variety
        if random.random() > 0.5:
             title = f"{title} for {random.choice(['Healthcare', 'Education', 'Finance', 'Security', 'Traffic', 'Agriculture'])}"

        row = {
            "id": i,
            "title": title,
            "description": f"A comprehensive {category.lower()} project focusing on {skills[0]} and {skills[1]} to solve real-world problems.",
            "category": category,
            "complexity": random.choice(["Beginner", "Intermediate", "Advanced"]),
            "required_skills": "|".join(skills),
            "trending": str(random.choice([True, False])).lower(),
            "preparation_months": random.randint(2, 6)
        }
        data.append(row)
    
    # Write to CSV
    filepath = os.path.join(DATA_DIR, "fyp_data.csv")
    with open(filepath, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["id", "title", "description", "category", "complexity", "required_skills", "trending", "preparation_months"])
        writer.writeheader()
        writer.writerows(data)
    print(f"[DONE] Saved to {filepath}")

def generate_student_data():
    data = []
    print(f"Generating {NUM_STUDENTS} students...")
    for i in range(1, NUM_STUDENTS + 1):
        semester = random.randint(1, 8)
        
        # Determine roll number based on semester (approx year)
        year = 2024 - (semester // 2)
        roll = f"{str(year)[-2:]}F-{random.randint(1000, 9999)}"
        
        interests = random.sample(CATEGORIES, k=random.randint(1, 3))
        
        row = {
            "roll_number": roll,
            "password": "1234", # Default password
            "name": f"{random.choice(NAMES_FIRST)} {random.choice(NAMES_LAST)}",
            "uni_name": random.choice(UNIVERSITIES),
            "current_semester": semester,
            "interests": "|".join(interests),
            "weak_subjects": "Calculus|Programming" if random.random() > 0.7 else "",
            "study_pace": random.choice(["Slow", "Moderate", "Fast"]),
            "learning_style": random.choice(["Visual", "Reading", "Practice"])
        }
        data.append(row)

    # Write to CSV
    filepath = os.path.join(DATA_DIR, "students.csv")
    with open(filepath, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["roll_number", "password", "name", "uni_name", "current_semester", "interests", "weak_subjects", "study_pace", "learning_style"])
        writer.writeheader()
        writer.writerows(data)
    print(f"[DONE] Saved to {filepath}")

if __name__ == "__main__":
    generate_fyp_data()
    generate_student_data()

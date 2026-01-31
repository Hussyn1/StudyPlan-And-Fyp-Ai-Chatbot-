import csv
import os
from typing import List, Optional, Dict

class CSVManager:
    _instance = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(CSVManager, cls).__new__(cls)
            cls._instance.initialized = False
        return cls._instance

    def __init__(self):
        if self.initialized:
            return
        
        # Paths
        base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        self.data_dir = os.path.join(base_dir, "data")
        
        self.fyp_projects = []
        self.courses = []
        self.students = []
        
        self.load_all_data()
        self.initialized = True

    def load_all_data(self):
        self.fyp_projects = self._read_csv("fyp_data.csv")
        self.courses = self._read_csv("courses.csv")
        self.students = self._read_csv("students.csv")
        print(f"CSVManager: Loaded {len(self.fyp_projects)} FYPs, {len(self.courses)} Courses, {len(self.students)} Students.")

    def _read_csv(self, filename: str) -> List[Dict]:
        filepath = os.path.join(self.data_dir, filename)
        if not os.path.exists(filepath):
            print(f"Warning: {filename} not found at {filepath}")
            return []
            
        data = []
        with open(filepath, mode='r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                # Basic cleaning
                clean_row = {}
                for k, v in row.items():
                    # Handle lists (pipe separated or comma separated)
                    if k in ['required_skills', 'interests', 'weak_subjects', 'topics']:
                         # prioritized pipe if present, else comma
                         if '|' in v:
                             clean_row[k] = [x.strip() for x in v.split('|')]
                         elif ',' in v:
                             clean_row[k] = [x.strip() for x in v.split(',')]
                         else:
                             clean_row[k] = [v.strip()] if v.strip() else []
                             
                    # Handle booleans
                    elif k == 'trending':
                        clean_row[k] = v.lower() == 'true'
                    
                    # Handle numbers
                    elif k in ['id', 'semester', 'credits', 'current_semester', 'preparation_months']:
                        try:
                            clean_row[k] = int(v)
                        except ValueError:
                             clean_row[k] = v
                    else:
                        clean_row[k] = v
                
                data.append(clean_row)
        return data

    # Accessors
    def get_fyp_projects(self) -> List[Dict]:
        return self.fyp_projects
    
    def get_fyp_project_by_id(self, project_id: str) -> Optional[Dict]:
        # Support string matching for ID
        for p in self.fyp_projects:
            if str(p['id']) == str(project_id):
                return p
        return None

    def get_courses(self) -> List[Dict]:
        return self.courses
        
    def get_course_by_code(self, code: str) -> Optional[Dict]:
        for c in self.courses:
            if c['code'] == code:
                return c
        return None
    
    def get_semester_courses(self, semester: int) -> List[Dict]:
        return [c for c in self.courses if c['semester'] == semester]

    def get_students(self) -> List[Dict]:
        return self.students
        
    def get_student_by_roll(self, roll_number: str) -> Optional[Dict]:
         for s in self.students:
            if s['roll_number'] == roll_number:
                return s
         return None

csv_manager = CSVManager()

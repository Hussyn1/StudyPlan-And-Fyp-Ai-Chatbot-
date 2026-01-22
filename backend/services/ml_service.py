from typing import List, Dict, Optional
from beanie import PydanticObjectId
from models import Student, Progress, Task, FYPProject, Course
import numpy as np

class MLService:
    
    @staticmethod
    async def calculate_skill_matrix(student_id: str) -> Dict:
        """Calculate student's skill levels across courses based on Progress"""
        completed_progress = await Progress.find(
            Progress.student_id == student_id,
            Progress.status == "completed"
        ).to_list()
        
        skill_matrix = {}
        for p in completed_progress:
            # Normalize grade to 1-5 stars
            grade = p.grade if p.grade is not None else (p.accuracy * 100)
            stars = int((grade / 100) * 5)
            
            course_name = p.course_name or "Unknown Course"
            skill_matrix[course_name] = {
                "stars": stars,
                "grade": grade,
                "course_id": p.course_id
            }
        
        return skill_matrix
    
    @staticmethod
    async def identify_weak_areas(student_id: str) -> List[Dict]:
        """Identify topics where student is struggling (low accuracy/failures)"""
        # In MongoDB version, we look at failed tasks
        failed_tasks = await Task.find(
            Task.student_id == student_id,
            Task.status == "failed"
        ).to_list()
        
        # Or look at Progress with low accuracy
        low_progress = await Progress.find(
            Progress.student_id == student_id,
            Progress.accuracy < 0.6
        ).to_list()

        weak_areas = []
        for p in low_progress:
             weak_areas.append({
                 "course_name": p.course_name,
                 "accuracy": p.accuracy
             })
             
        return weak_areas
    
    @staticmethod
    async def recommend_fyp_projects(student_id: str) -> List[Dict]:
        """Recommend FYP projects using weighted scoring algorithm"""
        student = await Student.get(PydanticObjectId(student_id))
        if not student:
            return []
            
        # Get skill matrix
        skill_matrix = await MLService.calculate_skill_matrix(student_id)
        
        # Get all projects
        all_fyps = await FYPProject.find_all().to_list()
        
        recommendations = []
        for fyp in all_fyps:
            match_score = 0
            
            # 1. Skill Match (20 points per skill)
            for req_skill in fyp.required_skills:
                # Fuzzy match skill with completed courses
                for course_name, data in skill_matrix.items():
                    if req_skill.lower() in course_name.lower() and data['stars'] >= 3:
                        match_score += 20
                        
            # 2. Interest Match (30 points)
            for interest in student.interests:
                if interest.lower() in fyp.category.lower():
                    match_score += 30
                    break
            
            # 3. Trending Bonus (10 points)
            if fyp.trending:
                match_score += 10
                
            if match_score > 0:
                recommendations.append({
                    "id": str(fyp.id),
                    "title": fyp.title,
                    "description": fyp.description,
                    "score": min(match_score, 100),
                    "match_score": min(match_score, 100) / 100,
                    "category": fyp.category,
                    "matching_skills": fyp.required_skills,
                    "rationale": f"Matches your skills in {[s for s in fyp.required_skills]} and interests."
                })
        
        # Sort by score
        recommendations.sort(key=lambda x: x['score'], reverse=True)
        return recommendations[:10]

ml_service = MLService()
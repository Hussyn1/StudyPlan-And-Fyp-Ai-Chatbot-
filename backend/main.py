from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import init_db
from routers import chat, student, courses, auth

app = FastAPI(title="AI Chatbot Backend")

# CORS Setup
origins = ["*"] # Allow all for development

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def on_startup():
    await init_db()

# Include Routers
app.include_router(auth.router, prefix="/auth", tags=["Authentication"])
app.include_router(chat.router, tags=["Chat"])
app.include_router(student.router, tags=["Student"])
app.include_router(courses.router, tags=["Courses"])

@app.get("/")
async def root():
    return {"message": "AI Chatbot API is running"}
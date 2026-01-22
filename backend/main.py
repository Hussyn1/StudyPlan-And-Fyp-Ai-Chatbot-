from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from database import init_db
from routers import chat, student, courses, auth

app = FastAPI(title="AI Study Guide API") # Updated title for premium feel

# CORS Setup
origins = ["*"] # Allow all for development

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    print(f"CRITICAL UNHANDLED ERROR: {exc}")
    import traceback
    traceback.print_exc()
    return JSONResponse(
        status_code=500,
        content={
            "status": "error",
            "message": "An internal server error occurred.",
            "detail": str(exc) if origins == ["*"] else None # Only show detail in dev
        }
    )

@app.on_event("startup")
async def on_startup():
    try:
        await init_db()
        
        # Auto-seed data if needed
        from seed_mongo import seed_initial_data
        await seed_initial_data()
    except Exception as e:
        print("\n" + "="*50)
        print(f"CRITICAL ERROR: Could not connect to MongoDB.")
        print(f"Details: {e}")
        print("THE SERVER IS STARTING BUT DATABASE FEATURES WILL NOT WORK.")
        print("="*50 + "\n")

# Include Routers
app.include_router(auth.router, prefix="/auth", tags=["Authentication"])
app.include_router(chat.router, tags=["Chat"])
app.include_router(student.router, tags=["Student"])
app.include_router(courses.router, tags=["Courses"])

@app.get("/")
async def root():
    return {"message": "AI Chatbot API is running"}

if __name__ == "__main__":
    import uvicorn
    # Bind to 0.0.0.0 to allow access from other devices (like the mobile app)
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
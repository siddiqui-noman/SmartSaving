from __future__ import annotations

import os
import uvicorn

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from chat_endpoint import router as chat_router
from auth import router as auth_router
import database
def _allowed_origins() -> list[str]:
    raw = os.getenv("CORS_ALLOW_ORIGINS", "*").strip()
    if raw == "*":
        return ["*"]
    return [origin.strip() for origin in raw.split(",") if origin.strip()]


app = FastAPI(
    title="SmartSaving Backend",
    description="FastAPI backend for SmartSaving assistant and pricing services.",
    version="1.0.0",
)

origins = _allowed_origins()
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(chat_router)
app.include_router(auth_router)

@app.on_event("startup")
async def startup_event():
    database.init_db()

@app.get("/health", tags=["system"])
async def health() -> dict[str, str]:
    return {"status": "ok"}

if __name__ == "__main__":
    uvicorn.run(
        "main:app", 
        host="0.0.0.0", 
        port=8000, 
        reload=True,
        log_level="info"
    )
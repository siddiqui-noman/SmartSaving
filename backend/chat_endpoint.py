"""
SmartSaving Backend - Chat Endpoint
Updated for the new google-genai SDK
"""
from __future__ import annotations
import os
from dotenv import load_dotenv

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
# NEW IMPORT SYNTAX
from google import genai
from google.genai import types

# 1. Load environment variables
load_dotenv()

# 2. Initialize the FastAPI Router
router = APIRouter(tags=["assistant"])

# 3. Initialize the New Gemini Client
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY:
    print("⚠️ WARNING: GEMINI_API_KEY not found!")

# Note: The new SDK uses a Client object instead of a global configure
client = genai.Client(api_key=GEMINI_API_KEY)

# --- DATA MODELS ---

class ChatRequest(BaseModel):
    message: str
    product_name: str
    current_price: float
    category: str

class ChatResponse(BaseModel):
    reply: str

# --- PROMPT LOGIC ---

SYSTEM_PROMPT = """
You are the SmartSaving Shopping Expert. 
Your goal is to provide concise, data-driven advice on whether a user should buy a product now or wait.

PERSONALITY:
- Professional, helpful, and slightly witty.
- Never give generic answers like "That's a good price." 
- Instead, say "At ₹[Price], this is 10 percent lower than the monthly average—Buy Now!"

CONSTRAINTS:
- Keep responses under 60 words.
- If the user asks about a different brand (like Samsung while looking at an iPhone), briefly compare them but stay focused on the current deal.
- If you don't have enough price history, tell the user to 'Track' the product in the app.

RULES:
1. Always analyze the 'Current Price' provided.
2. If the price seems high for the category, recommend WAIT.
3. If it looks like a good deal, recommend BUY NOW.
4. Keep reasoning to 2-3 short, helpful sentences.
5. Use a friendly, helpful tone."""



# --- THE ENDPOINT ---

@router.post("/chat", response_model=ChatResponse)
async def chat_with_assistant(payload: ChatRequest):
    if not GEMINI_API_KEY:
        raise HTTPException(status_code=500, detail="Gemini API Key missing.")

    # Build the full context for Gemini
    full_prompt = (
        f"{SYSTEM_PROMPT}\n\n"
        f"CONTEXT:\n"
        f"Product: {payload.product_name}\n"
        f"Category: {payload.category}\n"
        f"Current Price: ₹{payload.current_price}\n\n"
        f"USER QUESTION: {payload.message}"
    )

    try:
        # 3. Call Gemini using the NEW Client syntax
        response = client.models.generate_content(
            model='gemini-2.5-flash-lite',
            contents=full_prompt,
            config=types.GenerateContentConfig(
                temperature=0.3,
                max_output_tokens=800,
                safety_settings=[
                    types.SafetySetting(
                        category='HARM_CATEGORY_HATE_SPEECH',
                        threshold='BLOCK_NONE'
                    ),
                    types.SafetySetting(
                        category='HARM_CATEGORY_HARASSMENT',
                        threshold='BLOCK_NONE'
                    ),
                ]
            )
        )

        print("\n" + "="*30)
        print(f"DEBUG - Full Prompt Sent: {full_prompt[:100]}...") # Just the start
        print(f"DEBUG - Finish Reason: {response.candidates[0].finish_reason}")
        print(f"DEBUG - Full Response from Gemini: {response.text}")
        print("="*30 + "\n")

        # 4. Return the text reply
        if response.text:
            return ChatResponse(reply=response.text.strip())
        else:
            return ChatResponse(reply="Gemini returned an empty response.")

    except Exception as e:
        print(f"❌ Gemini SDK Error: {str(e)}")
        raise HTTPException(
            status_code=502, 
            detail=f"Error connecting to AI service: {str(e)}"
        )

@router.get("/chat/status")
async def get_status():
    return {"status": "Chat endpoint is online", "sdk": "google-genai"}
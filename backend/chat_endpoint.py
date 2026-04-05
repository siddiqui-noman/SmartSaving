"""
SmartSaving Backend - Chat Endpoint
Updated for the new google-genai SDK
"""
from __future__ import annotations

import os
from typing import Optional

from dotenv import load_dotenv
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from google import genai
from google.genai import types

load_dotenv()

router = APIRouter(tags=["assistant"])

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY:
    print("WARNING: GEMINI_API_KEY not found!")

client = genai.Client(api_key=GEMINI_API_KEY)


class ChatHistoryItem(BaseModel):
    role: str
    message: str


class PriceHistoryPoint(BaseModel):
    timestamp: str
    amazon_price: float
    flipkart_price: float
    best_price: float


class HistorySummary(BaseModel):
    points: int = 0
    latest_best_price: Optional[float] = None
    average_best_price_7d: Optional[float] = None
    average_best_price_30d: Optional[float] = None
    lowest_best_price_30d: Optional[float] = None
    highest_best_price_30d: Optional[float] = None
    trend_7d: Optional[str] = None


class ChatRequest(BaseModel):
    message: str
    product_id: Optional[str] = None
    product_name: str
    current_price: float
    category: str
    amazon_price: Optional[float] = None
    flipkart_price: Optional[float] = None
    best_platform: Optional[str] = None
    best_price: Optional[float] = None
    price_difference: Optional[float] = None
    savings_percentage: Optional[float] = None
    rating: Optional[float] = None
    reviews: Optional[int] = None
    is_tracked: Optional[bool] = None
    target_price: Optional[float] = None
    updated_at: Optional[str] = None
    conversation_history: list[ChatHistoryItem] = Field(default_factory=list)
    price_history: list[PriceHistoryPoint] = Field(default_factory=list)
    history_summary: Optional[HistorySummary] = None


class ChatResponse(BaseModel):
    reply: str


SYSTEM_PROMPT = """
You are the SmartSaving Shopping Expert.
Your goal is to provide concise, data-driven advice on whether a user should buy a product now or wait.

PERSONALITY:
- Professional, helpful, and slightly witty.
- Avoid generic responses. Use the specific pricing context provided.

CONSTRAINTS:
- Keep responses under 90 words.
- Prioritize product-specific reasoning using current platform prices, tracked history, and target price when present.
- If context is missing, say exactly what is missing instead of pretending.

RULES:
1. Compare Amazon and Flipkart when both prices are available.
2. Use the 7-day and 30-day summaries if they are present.
3. If the price is near a recent low, say so clearly.
4. If a target price is set, mention whether the product is above or below it.
5. End with a clear recommendation such as BUY NOW, WAIT, or TRACK LONGER.
"""


def _conversation_block(items: list[ChatHistoryItem]) -> str:
    if not items:
        return "- No prior conversation"
    return "\n".join(f"- {item.role}: {item.message}" for item in items[-6:])


def _price_history_block(items: list[PriceHistoryPoint]) -> str:
    if not items:
        return "- No price history available"
    return "\n".join(
        (
            f"- {item.timestamp}: "
            f"Amazon Rs {item.amazon_price}, "
            f"Flipkart Rs {item.flipkart_price}, "
            f"Best Rs {item.best_price}"
        )
        for item in items[-10:]
    )


def _summary_block(summary: Optional[HistorySummary]) -> str:
    if summary is None:
        return "- No history summary available"

    lines = [f"- History points: {summary.points}"]
    if summary.latest_best_price is not None:
        lines.append(f"- Latest best price: Rs {summary.latest_best_price}")
    if summary.average_best_price_7d is not None:
        lines.append(f"- 7-day average best price: Rs {summary.average_best_price_7d:.2f}")
    if summary.average_best_price_30d is not None:
        lines.append(f"- 30-day average best price: Rs {summary.average_best_price_30d:.2f}")
    if summary.lowest_best_price_30d is not None:
        lines.append(f"- 30-day low best price: Rs {summary.lowest_best_price_30d}")
    if summary.highest_best_price_30d is not None:
        lines.append(f"- 30-day high best price: Rs {summary.highest_best_price_30d}")
    if summary.trend_7d is not None:
        lines.append(f"- 7-day trend: {summary.trend_7d}")
    return "\n".join(lines)


def _rule_based_fallback(payload: ChatRequest) -> str:
    best_price = payload.best_price or payload.current_price
    average_7d = payload.history_summary.average_best_price_7d if payload.history_summary else None
    lowest_30d = payload.history_summary.lowest_best_price_30d if payload.history_summary else None
    trend_7d = payload.history_summary.trend_7d if payload.history_summary else None

    recommendation = "TRACK LONGER"
    reasons: list[str] = []

    if payload.amazon_price is not None and payload.flipkart_price is not None:
        reasons.append(
            f"{payload.best_platform or 'Best platform'} is cheaper by Rs {round(payload.price_difference or 0)}."
        )

    if lowest_30d is not None and best_price <= lowest_30d * 1.02:
        recommendation = "BUY NOW"
        reasons.append("Current price is very close to the recent 30-day low.")
    elif average_7d is not None and best_price < average_7d * 0.97:
        recommendation = "BUY NOW"
        reasons.append("Current price is meaningfully below the 7-day average.")
    elif average_7d is not None and best_price > average_7d * 1.03:
        recommendation = "WAIT"
        reasons.append("Current price is above the recent 7-day average.")

    if trend_7d == "down" and recommendation != "BUY NOW":
        recommendation = "WAIT"
        reasons.append("Recent trend is still moving downward.")
    elif trend_7d == "up" and recommendation == "TRACK LONGER":
        recommendation = "BUY NOW"
        reasons.append("Recent trend is moving upward, so waiting may cost more.")

    if payload.target_price is not None:
        if best_price <= payload.target_price:
            reasons.append("It has already met your target price.")
            recommendation = "BUY NOW"
        else:
            reasons.append(
                f"It is still Rs {round(best_price - payload.target_price)} above your target price."
            )

    if not reasons:
        reasons.append("There is not enough pricing history to make a stronger call yet.")

    joined = " ".join(reasons[:3])
    return f"{recommendation}: {joined}"


@router.post("/chat", response_model=ChatResponse)
async def chat_with_assistant(payload: ChatRequest):
    if not GEMINI_API_KEY:
        raise HTTPException(status_code=500, detail="Gemini API Key missing.")

    full_prompt = (
        f"{SYSTEM_PROMPT}\n\n"
        f"CONTEXT:\n"
        f"Product ID: {payload.product_id or 'Unknown'}\n"
        f"Product: {payload.product_name}\n"
        f"Category: {payload.category}\n"
        f"Current Best Price: Rs {payload.current_price}\n"
        f"Amazon Price: Rs {payload.amazon_price if payload.amazon_price is not None else 'Unknown'}\n"
        f"Flipkart Price: Rs {payload.flipkart_price if payload.flipkart_price is not None else 'Unknown'}\n"
        f"Best Platform: {payload.best_platform or 'Unknown'}\n"
        f"Best Price: Rs {payload.best_price if payload.best_price is not None else 'Unknown'}\n"
        f"Price Difference: Rs {payload.price_difference if payload.price_difference is not None else 'Unknown'}\n"
        f"Savings Percentage: {payload.savings_percentage if payload.savings_percentage is not None else 'Unknown'}\n"
        f"Rating: {payload.rating if payload.rating is not None else 'Unknown'}\n"
        f"Reviews: {payload.reviews if payload.reviews is not None else 'Unknown'}\n"
        f"Tracked in App: {payload.is_tracked if payload.is_tracked is not None else 'Unknown'}\n"
        f"Target Price: Rs {payload.target_price if payload.target_price is not None else 'Not set'}\n"
        f"Updated At: {payload.updated_at or 'Unknown'}\n\n"
        f"RECENT CONVERSATION:\n{_conversation_block(payload.conversation_history)}\n\n"
        f"PRICE HISTORY SUMMARY:\n{_summary_block(payload.history_summary)}\n\n"
        f"RECENT PRICE HISTORY:\n{_price_history_block(payload.price_history)}\n\n"
        f"USER QUESTION: {payload.message}"
    )

    try:
        response = client.models.generate_content(
            model="gemini-2.5-flash-lite",
            contents=full_prompt,
            config=types.GenerateContentConfig(
                temperature=0.3,
                max_output_tokens=800,
                safety_settings=[
                    types.SafetySetting(
                        category="HARM_CATEGORY_HATE_SPEECH",
                        threshold="BLOCK_NONE",
                    ),
                    types.SafetySetting(
                        category="HARM_CATEGORY_HARASSMENT",
                        threshold="BLOCK_NONE",
                    ),
                ],
            ),
        )

        print("\n" + "=" * 30)
        print(f"DEBUG - Full Prompt Sent: {full_prompt[:150]}...")
        print(f"DEBUG - Full Response from Gemini: {response.text}")
        print("=" * 30 + "\n")

        if response.text:
            return ChatResponse(reply=response.text.strip())
        return ChatResponse(reply="Gemini returned an empty response.")

    except Exception as exc:
        print(f"Gemini SDK Error: {exc}")
        return ChatResponse(reply=_rule_based_fallback(payload))


@router.get("/chat/status")
async def get_status():
    return {"status": "Chat endpoint is online", "sdk": "google-genai"}

"""
FastAPI Smart Assistant endpoint for SmartSaving.

How to use in your FastAPI app:
1) Include this router in your main app:
   app.include_router(router)
2) Replace ProductRepository methods with your real DB/services.
3) Set OPENAI_API_KEY and optional OPENAI_MODEL env vars.
"""

from __future__ import annotations

import os
from dataclasses import dataclass
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from openai import OpenAI
from pydantic import BaseModel, Field

router = APIRouter()


class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=2000)
    product_id: int = Field(..., gt=0)


class ChatResponse(BaseModel):
    reply: str


@dataclass
class PricePoint:
    timestamp: str
    price: float


@dataclass
class ProductSnapshot:
    product_id: int
    name: str
    current_price: float
    predicted_price: Optional[float]
    price_history: List[PricePoint]


class ProductRepository:
    """
    Replace these methods with your real data source.
    """

    async def get_product_snapshot(self, product_id: int) -> Optional[ProductSnapshot]:
        return None


def get_product_repository() -> ProductRepository:
    return ProductRepository()


def _derive_trend(history: List[PricePoint]) -> str:
    if len(history) < 2:
        return "stable"
    delta = history[-1].price - history[0].price
    if delta > 0:
        return "increasing"
    if delta < 0:
        return "decreasing"
    return "stable"


def _build_prompt(snapshot: ProductSnapshot, user_question: str) -> str:
    trend = _derive_trend(snapshot.price_history)
    predicted_price = (
        f"{snapshot.predicted_price:.2f}"
        if snapshot.predicted_price is not None
        else "Unknown"
    )
    history_lines = (
        "\n".join(
            f"- {point.timestamp}: {point.price:.2f}"
            for point in reversed(snapshot.price_history[-14:])
        )
        or "- No history available"
    )

    return (
        "You are a smart shopping assistant.\n\n"
        f"Product: {snapshot.name}\n"
        f"Current price: {snapshot.current_price:.2f}\n"
        f"Predicted price: {predicted_price}\n"
        f"Trend: {trend}\n"
        "Price history (latest first up to 14 rows):\n"
        f"{history_lines}\n\n"
        f"User question: {user_question}\n\n"
        "Give a clear recommendation (Buy Now or Wait) with concise reasoning. "
        "Mention key factors from current price, trend, and prediction."
    )


def _get_openai_client() -> OpenAI:
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        raise HTTPException(status_code=500, detail="OPENAI_API_KEY is not configured.")
    return OpenAI(api_key=api_key)


@router.post("/chat", response_model=ChatResponse)
async def chat_with_assistant(
    payload: ChatRequest,
    repo: ProductRepository = Depends(get_product_repository),
) -> ChatResponse:
    message = payload.message.strip()
    if not message:
        raise HTTPException(status_code=400, detail="Message cannot be empty.")

    snapshot = await repo.get_product_snapshot(payload.product_id)
    if not snapshot:
        raise HTTPException(status_code=404, detail="Product not found.")

    prompt = _build_prompt(snapshot, message)

    client = _get_openai_client()
    model = os.getenv("OPENAI_MODEL", "gpt-5-mini")

    try:
        result = client.responses.create(
            model=model,
            input=[
                {
                    "role": "system",
                    "content": "You help users decide when to buy products by using price data.",
                },
                {"role": "user", "content": prompt},
            ],
            temperature=0.2,
            max_output_tokens=300,
        )
        reply = (result.output_text or "").strip()
        if not reply:
            raise HTTPException(status_code=502, detail="Empty response from LLM.")
        return ChatResponse(reply=reply)
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Chat service failed: {exc}") from exc



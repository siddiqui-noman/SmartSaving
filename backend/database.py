import sqlite3
import os
from datetime import datetime
from typing import Optional, Dict, Any

DB_PATH = os.path.join(os.path.dirname(__file__), "app.db")

def get_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id TEXT PRIMARY KEY,
            email TEXT UNIQUE NOT NULL,
            name TEXT NOT NULL,
            hashed_password TEXT NOT NULL,
            created_at TEXT NOT NULL
        )
    """)
    conn.commit()
    conn.close()

def get_user_by_email(email: str) -> Optional[Dict[str, Any]]:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users WHERE email = ?", (email,))
    row = cursor.fetchone()
    conn.close()
    if row:
        user_dict = dict(row)
        if 'created_at' in user_dict:
            user_dict['createdAt'] = user_dict.pop('created_at')
        return user_dict
    return None

def create_user(user_id: str, email: str, name: str, hashed_password: str) -> Dict[str, Any]:
    created_at = datetime.utcnow().isoformat()
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO users (id, email, name, hashed_password, created_at) VALUES (?, ?, ?, ?, ?)",
        (user_id, email, name, hashed_password, created_at)
    )
    conn.commit()
    conn.close()
    
    return {
        "id": user_id,
        "email": email,
        "name": name,
        "createdAt": created_at
    }

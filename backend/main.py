from fastapi import FastAPI, HTTPException
import mysql.connector
import os
import hashlib
import requests
from pydantic import BaseModel

app = FastAPI()

# ───────────────── DATABASE ─────────────────
def get_db():
    return mysql.connector.connect(
        host=os.getenv("MYSQLHOST"),
        user=os.getenv("MYSQLUSER"),
        password=os.getenv("MYSQLPASSWORD"),
        database=os.getenv("MYSQLDATABASE"),
        port=int(os.getenv("MYSQLPORT", 3306))
    )

def init_db():
    db = get_db()
    cursor = db.cursor()

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(255),
            username VARCHAR(255) UNIQUE,
            password VARCHAR(255)
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS tasks (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT,
            name VARCHAR(255),
            scheduled_date VARCHAR(20),
            scheduled_time VARCHAR(10),
            status VARCHAR(50) DEFAULT 'pending',
            FOREIGN KEY (user_id) REFERENCES users(id)
        )
    """)

    db.commit()
    cursor.close()
    db.close()

init_db()

def hash_password(password: str) -> str:
    return hashlib.sha256(password.encode()).hexdigest()

# ───────────────── HOME ─────────────────
@app.get("/")
def home():
    return {"status": "working"}

# ───────────────── AUTH ─────────────────
@app.post("/register")
def register(data: dict):
    db = get_db()
    cursor = db.cursor()
    try:
        cursor.execute(
            "INSERT INTO users (name, username, password) VALUES (%s, %s, %s)",
            (data["name"], data["username"], hash_password(data["password"]))
        )
        db.commit()
        return {"message": "Account created successfully"}
    except mysql.connector.IntegrityError:
        raise HTTPException(status_code=400, detail="Username already exists")
    finally:
        cursor.close()
        db.close()


@app.post("/login")
def login(data: dict):
    db = get_db()
    cursor = db.cursor(dictionary=True)

    cursor.execute(
        "SELECT * FROM users WHERE username=%s AND password=%s",
        (data["username"], hash_password(data["password"]))
    )

    user = cursor.fetchone()
    cursor.close()
    db.close()

    if not user:
        raise HTTPException(status_code=401, detail="Invalid username or password")

    return {
        "id": user["id"],
        "name": user["name"],
        "username": user["username"]
    }

# ───────────────── TASKS ─────────────────
@app.post("/tasks")
def add_task(task: dict):
    db = get_db()
    cursor = db.cursor()

    cursor.execute(
        "INSERT INTO tasks (user_id, name, scheduled_date, scheduled_time) VALUES (%s, %s, %s, %s)",
        (task["user_id"], task["name"], task.get("scheduled_date", ""), task.get("scheduled_time", ""))
    )

    db.commit()
    cursor.close()
    db.close()
    return {"message": "Task added"}


@app.get("/tasks/{user_id}")
def get_tasks(user_id: int):
    db = get_db()
    cursor = db.cursor(dictionary=True)

    cursor.execute(
        "SELECT * FROM tasks WHERE user_id=%s ORDER BY scheduled_date ASC, scheduled_time ASC",
        (user_id,)
    )

    tasks = cursor.fetchall()
    cursor.close()
    db.close()
    return tasks


@app.put("/tasks/{task_id}")
def update_task(task_id: int):
    db = get_db()
    cursor = db.cursor()

    cursor.execute("UPDATE tasks SET status='done' WHERE id=%s", (task_id,))
    db.commit()

    cursor.close()
    db.close()
    return {"message": "Task marked as done"}


@app.delete("/tasks/{task_id}")
def delete_task(task_id: int):
    db = get_db()
    cursor = db.cursor()

    cursor.execute("DELETE FROM tasks WHERE id=%s", (task_id,))
    db.commit()

    cursor.close()
    db.close()
    return {"message": "Task deleted"}


@app.get("/productivity/{user_id}")
def get_productivity(user_id: int):
    db = get_db()
    cursor = db.cursor(dictionary=True)

    cursor.execute("SELECT COUNT(*) as total FROM tasks WHERE user_id=%s", (user_id,))
    total = cursor.fetchone()["total"]

    cursor.execute("SELECT COUNT(*) as completed FROM tasks WHERE user_id=%s AND status='done'", (user_id,))
    completed = cursor.fetchone()["completed"]

    cursor.close()
    db.close()

    score = int((completed / total) * 100) if total > 0 else 0

    return {
        "total_tasks": total,
        "completed_tasks": completed,
        "productivity": score
    }


@app.get("/plan/{user_id}")
def plan_day(user_id: int):
    db = get_db()
    cursor = db.cursor(dictionary=True)

    cursor.execute(
        "SELECT * FROM tasks WHERE user_id=%s ORDER BY scheduled_date ASC, scheduled_time ASC",
        (user_id,)
    )

    tasks = cursor.fetchall()
    cursor.close()
    db.close()
    return tasks

# ───────────────── 🤖 FREE AI CHAT ─────────────────
class ChatRequest(BaseModel):
    message: str


@app.post("/chat")
def chat(req: ChatRequest):
    try:
        response = requests.post(
            "https://router.huggingface.co/hf-inference/models/google/flan-t5-base",
            headers={
                "Authorization": f"Bearer {os.getenv('HF_TOKEN')}"
            },
            json={
                "inputs": f"Answer this: {req.message}",
                "parameters": {
                    "max_new_tokens": 100
                }
            },
            timeout=15
        )

        # 🔥 handle empty response
        if not response.text:
            return {"reply": "AI is starting... try again"}

        try:
            data = response.json()
        except:
            return {"reply": "Invalid AI response"}

        print(data)

        # 🔥 correct parsing
        if isinstance(data, list) and len(data) > 0:
            reply = data[0].get("generated_text", "No response")
        elif "error" in data:
            reply = "AI error: " + data["error"]
        else:
            reply = str(data)

        return {"reply": reply}

    except Exception as e:
        return {"reply": str(e)}
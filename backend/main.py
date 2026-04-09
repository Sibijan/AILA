from fastapi import FastAPI
import mysql.connector
import os

app = FastAPI()

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
        CREATE TABLE IF NOT EXISTS tasks (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(255),
            scheduled_date VARCHAR(20),
            scheduled_time VARCHAR(10),
            status VARCHAR(50) DEFAULT 'pending'
        )
    """)
    db.commit()
    cursor.close()
    db.close()

init_db()

@app.get("/")
def home():
    return {"status": "working"}

@app.post("/tasks")
def add_task(task: dict):
    db = get_db()
    cursor = db.cursor()
    cursor.execute(
        "INSERT INTO tasks (name, scheduled_date, scheduled_time) VALUES (%s, %s, %s)",
        (task["name"], task.get("scheduled_date", ""), task.get("scheduled_time", ""))
    )
    db.commit()
    cursor.close()
    db.close()
    return {"message": "Task added"}

@app.get("/tasks")
def get_tasks():
    db = get_db()
    cursor = db.cursor(dictionary=True)
    cursor.execute("SELECT * FROM tasks ORDER BY scheduled_date ASC, scheduled_time ASC")
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

@app.get("/productivity")
def get_productivity():
    db = get_db()
    cursor = db.cursor(dictionary=True)
    cursor.execute("SELECT COUNT(*) as total FROM tasks")
    total = cursor.fetchone()["total"]
    cursor.execute("SELECT COUNT(*) as completed FROM tasks WHERE status='done'")
    completed = cursor.fetchone()["completed"]
    cursor.close()
    db.close()
    score = int((completed / total) * 100) if total > 0 else 0
    return {"total_tasks": total, "completed_tasks": completed, "productivity": score}

@app.get("/plan")
def plan_day():
    db = get_db()
    cursor = db.cursor(dictionary=True)
    cursor.execute("SELECT * FROM tasks ORDER BY scheduled_date ASC, scheduled_time ASC")
    tasks = cursor.fetchall()
    cursor.close()
    db.close()
    return tasks
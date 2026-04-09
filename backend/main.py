from fastapi import FastAPI
import mysql.connector

db = mysql.connector.connect(                   #connecting and saving in gb
    host="localhost",
    user="root",
    password="root", 
    database="ai_life"
)

cursor = db.cursor(dictionary=True)

app = FastAPI()



@app.get("/")
def home():
    return {"status": "working"}


# ADD TASK
@app.post("/tasks")
def add_task(task: dict):
    sql = "INSERT INTO tasks (name, priority) VALUES (%s, %s)"
    values = (task["name"], task["priority"])
    
    cursor.execute(sql, values)
    db.commit()

    return {"message": "Task added to DB"}


# GET TASKS
@app.get("/tasks")
def get_tasks():
    cursor.execute("SELECT * FROM tasks ORDER BY priority DESC")
    result = cursor.fetchall()
    return result

#PUT TASKS
@app.put("/tasks/{task_id}")
def update_task(task_id: int):
    cursor.execute(
        "UPDATE tasks SET status='done' WHERE id=%s",
        (task_id,)
    )
    db.commit()

    if cursor.rowcount == 0:
        return {"message": "Task not found"}

    return {"message": "Task marked as done"}

@app.get("/productivity")
def get_productivity():
    cursor.execute("SELECT COUNT(*) as total FROM tasks")
    total = cursor.fetchone()["total"]

    if total == 0:
        return {"productivity": 0}

    cursor.execute("SELECT COUNT(*) as completed FROM tasks WHERE status='done'")
    completed = cursor.fetchone()["completed"]

    score = int((completed / total) * 100)

    return {
        "total_tasks": total,
        "completed_tasks": completed,
        "productivity": score
    }

#DELETE TASK
@app.delete("/tasks/{task_id}")
def delete_task(task_id: int):
    sql = "DELETE FROM tasks WHERE id=%s"
    cursor.execute(sql, (task_id,))
    db.commit()

    if cursor.rowcount == 0:
        return {"message": "Task not found"}

    return {"message": "Task deleted successfully"}

#planner api
@app.get("/plan")
def plan_day():
    cursor.execute("SELECT * FROM tasks ORDER BY priority DESC")
    tasks = cursor.fetchall()

    if not tasks:
        return {"message": "No tasks available"}

    plan = []
    time = 9  # start at 9 AM

    for task in tasks:
        if time < 12:
            formatted_time = f"{time}:00 AM"
        else:
            formatted_time = f"{time-12}:00 PM"

        plan.append({
            "task": task["name"],
            "time": formatted_time
        })

        time += 1

    return plan
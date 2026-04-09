from fastapi import FastAPI

app = FastAPI()

# Temporary storage (instead of DB)
tasks = []


@app.get("/")
def home():
    return {"status": "working"}


# ADD TASK
@app.post("/tasks")
def add_task(task: dict):
    task["id"] = len(tasks) + 1
    task["status"] = "pending"
    tasks.append(task)
    return {"message": "Task added"}


# GET TASKS
@app.get("/tasks")
def get_tasks():
    return sorted(tasks, key=lambda x: x["priority"], reverse=True)


# UPDATE TASK
@app.put("/tasks/{task_id}")
def update_task(task_id: int):
    for task in tasks:
        if task["id"] == task_id:
            task["status"] = "done"
            return {"message": "Task marked as done"}
    return {"message": "Task not found"}


# DELETE TASK
@app.delete("/tasks/{task_id}")
def delete_task(task_id: int):
    for task in tasks:
        if task["id"] == task_id:
            tasks.remove(task)
            return {"message": "Task deleted"}
    return {"message": "Task not found"}


# PRODUCTIVITY
@app.get("/productivity")
def get_productivity():
    total = len(tasks)
    completed = sum(1 for task in tasks if task["status"] == "done")
    score = int((completed / total) * 100) if total > 0 else 0

    return {
        "total_tasks": total,
        "completed_tasks": completed,
        "productivity": score
    }


# PLAN
@app.get("/plan")
def plan_day():
    if not tasks:
        return {"message": "No tasks available"}

    sorted_tasks = sorted(tasks, key=lambda x: x["priority"], reverse=True)

    plan = []
    time = 9  # start at 9 AM

    for task in sorted_tasks:
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
import streamlit as st
import requests
import os
from datetime import datetime

# ── Page config (must be first) ──────────────────────────────
st.set_page_config(
    page_title="AILA – AI Life Assistant",
    page_icon="🧠",
    layout="centered"
)

# ── Load CSS ─────────────────────────────────────────────────
def load_css():
    css_path = os.path.join(os.path.dirname(__file__), "style.css")
    with open(css_path) as f:
        st.markdown(f"<style>{f.read()}</style>", unsafe_allow_html=True)

load_css()

BASE_URL = "http://127.0.0.1:8000"

PRIORITY_LABELS = {
    1: "🔴 High",
    2: "🟡 Medium",
    3: "🟢 Low",
}

# ── Hero Header ──────────────────────────────────────────────
today = datetime.now().strftime("%A, %B %d")
st.title("🧠 AILA")
st.markdown(
    f"<p style='text-align:center; color:#55557a; font-size:0.85rem; margin-top:-0.75rem; margin-bottom:2rem;'>"
    f"Your AI Life Assistant · {today}</p>",
    unsafe_allow_html=True
)

# ── Quick Stats Bar ──────────────────────────────────────────
try:
    prod_res = requests.get(f"{BASE_URL}/productivity", timeout=3)
    prod_data = prod_res.json()
    total = prod_data.get("total_tasks", 0)
    completed = prod_data.get("completed_tasks", 0)
    pending = total - completed
    score = prod_data.get("productivity", 0)

    c1, c2, c3 = st.columns(3)
    c1.metric("Total Tasks", total)
    c2.metric("Completed", completed)
    c3.metric("Productivity", f"{score}%")
    st.markdown("<hr style='border-color:#1e1e38; margin: 1.5rem 0;'>", unsafe_allow_html=True)
except Exception:
    st.warning("⚠️ Backend not reachable. Make sure FastAPI is running on port 8000.")

# ── ADD TASK ─────────────────────────────────────────────────
st.header("➕ Add Task")

name = st.text_input("Task Name", placeholder="e.g. Study Python, Go for a run…")
priority = st.selectbox(
    "Priority",
    options=[1, 2, 3],
    format_func=lambda x: PRIORITY_LABELS[x]
)

if st.button("Add Task"):
    if not name.strip():
        st.warning("Please enter a task name.")
    else:
        res = requests.post(f"{BASE_URL}/tasks", json={"name": name, "priority": priority})
        if res.status_code == 200:
            st.success(f"✅ **{name}** added successfully!")
            st.rerun()
        else:
            st.error("Failed to add task.")

st.markdown("<hr style='border-color:#1e1e38; margin: 1.5rem 0;'>", unsafe_allow_html=True)

# ── ALL TASKS ────────────────────────────────────────────────
st.header("📋 All Tasks")

try:
    res = requests.get(f"{BASE_URL}/tasks", timeout=3)
    tasks = res.json()

    if not tasks:
        st.markdown(
            "<p style='text-align:center; color:#55557a; padding: 1.5rem 0;'>No tasks yet. Add one above!</p>",
            unsafe_allow_html=True
        )
    else:
        for task in tasks:
            is_done = task["status"] == "done"
            badge = f'<span class="badge-done">✓ Done</span>' if is_done else f'<span class="badge-pending">⏳ Pending</span>'
            priority_chip = f'<span class="priority-chip">{PRIORITY_LABELS.get(task["priority"], task["priority"])}</span>'

            col1, col2 = st.columns([5, 1])
            with col1:
                st.markdown(f"""
                <div class="task-card">
                    <strong>#{task['id']} &nbsp; {task['name']}</strong><br>
                    <span style="margin-top:6px; display:inline-block;">{priority_chip}{badge}</span>
                </div>
                """, unsafe_allow_html=True)

            with col2:
                st.markdown("<div style='height:12px'></div>", unsafe_allow_html=True)
                if not is_done:
                    if st.button("✓", key=f"done_{task['id']}", help="Mark as done"):
                        requests.put(f"{BASE_URL}/tasks/{task['id']}")
                        st.rerun()
                else:
                    if st.button("🗑", key=f"del_{task['id']}", help="Delete task"):
                        requests.delete(f"{BASE_URL}/tasks/{task['id']}")
                        st.rerun()
except Exception:
    st.error("Could not load tasks.")

st.markdown("<hr style='border-color:#1e1e38; margin: 1.5rem 0;'>", unsafe_allow_html=True)

# ── DAILY PLAN ───────────────────────────────────────────────
st.header("🗓️ Daily Plan")

if st.button("Generate My Plan"):
    res = requests.get(f"{BASE_URL}/plan")
    plan = res.json()

    if isinstance(plan, list) and plan:
        st.markdown("<div style='margin-top:1rem'>", unsafe_allow_html=True)
        for item in plan:
            st.markdown(f"""
            <div class="plan-item">
                <span class="plan-time">🕒 {item['time']}</span>
                <span class="plan-task">{item['task']}</span>
            </div>
            """, unsafe_allow_html=True)
        st.markdown("</div>", unsafe_allow_html=True)
    else:
        st.info("No tasks to plan. Add some tasks first!")

st.markdown("<hr style='border-color:#1e1e38; margin: 1.5rem 0;'>", unsafe_allow_html=True)

# ── PRODUCTIVITY ─────────────────────────────────────────────
st.header("📊 Productivity")

if st.button("Refresh Stats"):
    st.rerun()

try:
    res = requests.get(f"{BASE_URL}/productivity", timeout=3)
    data = res.json()
    score = data.get("productivity", 0)

    colour = "#34d399" if score >= 70 else "#fbbf24" if score >= 40 else "#f87171"
    label = "🔥 Crushing it!" if score >= 70 else "📈 Good progress" if score >= 40 else "💪 Keep going"

    st.markdown(f"""
    <div style="text-align:center; margin: 1rem 0 0.5rem;">
        <span style="font-family:'Syne',sans-serif; font-size:3rem; font-weight:800; color:{colour};">{score}%</span><br>
        <span style="color:#55557a; font-size:0.85rem;">{label} · {data.get('completed_tasks',0)} of {data.get('total_tasks',0)} tasks done</span>
    </div>
    """, unsafe_allow_html=True)

    st.progress(score / 100)
except Exception:
    st.error("Could not load productivity data.")

# ── Footer ───────────────────────────────────────────────────
st.markdown(
    "<p style='text-align:center; color:#2d2d4e; font-size:0.75rem; margin-top:3rem;'>AILA · Built with FastAPI + Streamlit</p>",
    unsafe_allow_html=True
)
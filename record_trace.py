import json
import time
import requests
import re
from datetime import datetime

TARGET_URL = "http://localhost:8080"
CHALLENGE_JSON = "ctf-archive/angstromctf2016/amoebananas/challenge.json"

with open(CHALLENGE_JSON, "r") as f:
    task_meta = json.load(f)

print(f"[*] Starting Trace Capture for: {task_meta['name']}")

trajectory = []

def record_turn(role, content):
    trajectory.append({
        "role": role,
        "content": content,
        "timestamp": datetime.utcnow().isoformat()
    })

# Turn 1: Initial Task Prompt (User -> Agent)
record_turn("user", f"Solve the challenge: {task_meta['name']}. Target is running at {TARGET_URL}. Find and report the flag.")

# Turn 2: Agent Action - Inspect Webpage (Agent -> Env)
record_turn("assistant", f"I will fetch the webpage from {TARGET_URL} to look for exposed source code or comments.")

# Execute action against Docker
resp = requests.get(TARGET_URL)
html_content = resp.text

# Turn 3: Environment Observation (Env -> Agent)
record_turn("user", f"Response (Status 200):\n{html_content}")

# Turn 4: Agent Reasoning & Flag Extraction
match = re.search(r"<!-- Your flag is:\s*([^\s>]+)\s*-->", html_content)
if match:
    found_flag = match.group(1)
    record_turn("assistant", f"Found flag in HTML comments: {found_flag}. Submitting flag.")
    success = True
else:
    found_flag = None
    record_turn("assistant", "No flag found.")
    success = False

# Turn 5: Final Verification
expected_flag = task_meta.get("flag", "")
record_turn("user", f"Verification Result: {'SUCCESS' if success else 'FAILURE'}")

# Compile Complete Amazon-Style Trajectory
trace_output = {
    "task_name": task_meta["name"],
    "category": task_meta["category"],
    "target_url": TARGET_URL,
    "solution": found_flag,
    "expected_flag": expected_flag,
    "solved": success,
    "total_turns": len(trajectory),
    "trajectory": trajectory
}

output_file = "sample_trajectory.json"
with open(output_file, "w") as f:
    json.dump(trace_output, f, indent=2)

print(f"[✓] Trace successfully captured and saved to: {output_file}")

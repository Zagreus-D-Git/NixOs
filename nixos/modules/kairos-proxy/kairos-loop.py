#!/usr/bin/env python3
import os
import sys
import json
import subprocess
import urllib.request

PROXY_URL = "http://127.0.0.1:18888/api/generate"
WORKSPACE = "/home/zagreus/dev-agent-workspace"
SPEC_FILE = "/home/zagreus/nixos-config/specs/features/01_local_agent_test/plan.md"

def get_spec():
    with open(SPEC_FILE, "r") as f:
        return f.read()

def query_local_llm(prompt):
    print("[*] Contacting Local Qwen-Coder via Kairos Proxy...")
    system_prompt = (
        "You are an isolated developer agent. Provide ONLY pure Python code wrapped "
        "inside a single markdown block ```python ... ```. Do not explain anything."
    )

    payload = {
        "model": "qwen2.5-coder:7b",
        "prompt": f"{system_prompt}\n\nTask Specification:\n{prompt}",
        "stream": False
    }

    req = urllib.request.Request(
        PROXY_URL,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"}
    )

    with urllib.request.urlopen(req) as response:
        res = json.loads(response.read().decode("utf-8"))
        return res["response"]

def extract_code(raw_response):
    lines = raw_response.split("\n")
    code_lines = []
    in_block = False
    for line in lines:
        if line.strip().startswith("```python"):
            in_block = True
            continue
        if line.strip().startswith("```") and in_block:
            in_block = False
            break
        if in_block:
            code_lines.append(line)
    return "\n".join(code_lines) if code_lines else raw_response

def main():
    if not os.path.exists(WORKSPACE):
        print(f"[-] Workspace {WORKSPACE} missing. Make sure systemd-tmpfiles created it.")
        sys.exit(1)

    spec = get_spec()
    raw_out = query_local_llm(spec)
    clean_code = extract_code(raw_out)

    # Write the target code straight to your isolated dev workspace
    target_path = os.path.join(WORKSPACE, "fib.py")
    with open(target_path, "w") as f:
        f.write(clean_code)
    print(f"[+] Code written cleanly to execution workspace: {target_path}")

    # Generate a dynamic unit test inside the workspace to execute the validation layer
    test_path = os.path.join(WORKSPACE, "test_fib.py")
    with open(test_path, "w") as f:
        f.write(
            "from fib import fibonacci\n"
            "def test_fib():\n"
            "    assert fibonacci(1) == 1\n"
            "    assert fibonacci(5) == 5\n"
            "    assert fibonacci(10) == 55\n"
        )

    # STEP C: Execute validation INSIDE the bubblewrap jail sandbox
    print("[*] Spawning sandboxed verification environment via dev-agent...")
    result = subprocess.run(
        ["dev-agent", "pytest", os.path.basename(test_path)],
        capture_output=True,
        text=True
    )

    print("\n=== JAIL EXECUTION LOGS ===")
    print(result.stdout)
    if result.returncode == 0:
        print("[SUCCESS] Agent task validated and completed successfully inside the jail boundary.")
    else:
        print("[-] Verification failed. Error logs:\n", result.stderr)

if __name__ == "__main__":
    main()

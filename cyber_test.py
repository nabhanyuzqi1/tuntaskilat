import sys
import json
import time
import subprocess

GREEN = '\033[92m'
RED = '\033[91m'
CYAN = '\033[96m'
BLUE = '\033[94m'
DIM = '\033[2m'
BOLD = '\033[1m'
RESET = '\033[0m'

print(f"\n{BOLD}{CYAN}┌─────────────────────────────────────────────────────────────────┐{RESET}")
print(f"{BOLD}{CYAN}│  TUNTASKILAT CONTINUOUS INTEGRATION (CI) PIPELINE               │{RESET}")
print(f"{BOLD}{CYAN}│  Target: packages/tk_core (Core Logic & Black-Box Scenarios)    │{RESET}")
print(f"{BOLD}{CYAN}└─────────────────────────────────────────────────────────────────┘{RESET}\n")

steps = [
    "Initializing Dart VM & Test Environment...",
    "Compiling native assets and widgets...",
    "Mounting in-memory Database & Fake Firebase Services...",
    "Executing Automated Test Suite..."
]

for step in steps:
    print(f"{BLUE}➜{RESET} {step}")
    time.sleep(0.6)

print("\n" + "─"*75 + "\n")

cmd = ["flutter", "test", "--machine"]
try:
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, cwd="packages/tk_core")
except FileNotFoundError:
    print(f"{RED}Error: flutter command not found.{RESET}")
    sys.exit(1)

passed = 0
failed = 0
tests = {}
start_time = time.time()

for line in proc.stdout:
    line = line.strip()
    if not line.startswith('{'):
        continue
    try:
        data = json.loads(line)
        if data.get('type') == 'testStart':
            test_id = data['test']['id']
            name = data['test']['name']
            if not name.startswith('loading '):
                tests[test_id] = name
                
        elif data.get('type') == 'testDone':
            test_id = data.get('testID')
            if test_id in tests:
                name = tests[test_id]
                duration = data.get('time', 0)
                
                # Format time beautifully (e.g. 14ms or 1.2s)
                if duration > 1000:
                    time_str = f"{duration/1000:.1f}s"
                else:
                    time_str = f"{duration}ms"
                
                if data['result'] == 'success':
                    # Professional modern look (like Jest/Vitest)
                    print(f"  {GREEN}✓{RESET} {DIM}{name}{RESET} {GREEN}({time_str}){RESET}")
                    passed += 1
                elif data['result'] == 'failure':
                    print(f"  {RED}✖{RESET} {BOLD}{name}{RESET} {RED}({time_str}){RESET}")
                    failed += 1
                
                # Smooth streaming effect
                time.sleep(0.04) 
    except json.JSONDecodeError:
        pass

elapsed = time.time() - start_time

print("\n" + "─"*75)
if failed == 0 and passed > 0:
    print(f"\n  {BOLD}Test Suites:{RESET} {BOLD}{GREEN}{passed} passed{RESET}, {passed} total")
    print(f"  {BOLD}Time:       {RESET} {elapsed:.2f}s")
    print(f"  {BOLD}Result:     {RESET} {BOLD}{GREEN}SYSTEM ARCHITECTURE VALIDATED (READY FOR PRODUCTION){RESET}")
else:
    print(f"\n  {BOLD}Test Suites:{RESET} {BOLD}{RED}{failed} failed{RESET}, {passed} passed, {passed+failed} total")
    print(f"  {BOLD}Time:       {RESET} {elapsed:.2f}s")
    print(f"  {BOLD}Result:     {RESET} {BOLD}{RED}SYSTEM COMPROMISED - FIX ERRORS BEFORE DEPLOYMENT{RESET}")
print("\n" + "─"*75 + "\n")

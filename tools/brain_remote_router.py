import os
import json
import re
from pathlib import Path

def parse_issue_body(body):
    """Simple parser for the issue template structure."""
    data = {}
    sections = {
        "Task Classification": "classification",
        "Blast Radius Analysis (BRA)": "blast_radius",
        "Target File(s)": "files",
        "Bounded Goal": "goal",
        "Working Truth": "truth",
        "Creator Intent": "intent",
        "Technical Risk": "risk",
        "Identity / Constraint Check": "risk"
    }
    
    current_key = None
    for line in body.split('\n'):
        line = line.strip()
        if line.startswith('### '):
            header = line[4:].strip()
            current_key = sections.get(header)
        elif current_key and line and not line.startswith('_'):
            if current_key not in data:
                data[current_key] = line
            else:
                data[current_key] += "\n" + line
    
    return data

def main():
    event_path = os.getenv('GITHUB_EVENT_PATH')
    kernel_path = Path("docs/ai/agents/BRAIN_KERNEL.md")
    
    payload = {
        "version": "2.2-remote",
        "kernel_verified": False,
        "classification": "Unknown",
        "blast_radius": "Tier 0: Docs/Naming",
        "files": [],
        "goal": "Unknown",
        "truth": "",
        "intent": "",
        "risk": "",
        "constraint": ""
    }
    
    # 1. Verify Kernel
    if kernel_path.exists():
        payload["kernel_verified"] = True
        # Could extract version from kernel file if needed
    
    # 2. Extract Data
    if os.getenv('GITHUB_EVENT_NAME') == 'workflow_dispatch':
        payload["classification"] = os.getenv('DISPATCH_TASK', 'Unknown')
        payload["blast_radius"] = os.getenv('DISPATCH_BRA', 'Tier 0: Docs/Naming')
        payload["files"] = [f.strip() for f in os.getenv('DISPATCH_FILES', '').split(',') if f.strip()]
        payload["goal"] = os.getenv('DISPATCH_GOAL', 'Unknown')
        payload["truth"] = os.getenv('DISPATCH_TRUTH', '')
        payload["intent"] = os.getenv('DISPATCH_INTENT', '')
        payload["risk"] = os.getenv('DISPATCH_CONSTRAINT', '')
        payload["constraint"] = payload["risk"]
    elif event_path:
        with open(event_path, 'r') as f:
            event = json.load(f)
            
        if 'issue' in event:
            body = event['issue'].get('body', '')
            issue_data = parse_issue_body(body)
            payload.update(issue_data)
            # Ensure files is a list
            if isinstance(payload.get('files'), str):
                payload['files'] = [f.strip() for f in payload['files'].split('\n') if f.strip()]
            if payload.get('risk') and not payload.get('constraint'):
                payload['constraint'] = payload['risk']
    
    # 3. Save Payload
    with open('.brain_payload.json', 'w') as f:
        json.dump(payload, f, indent=2)
    
    print(f"BRAIN Remote: Normalized payload generated for {payload['goal'][:50]}...")

if __name__ == "__main__":
    main()

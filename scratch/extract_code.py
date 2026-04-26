import json
import os

log_path = r'C:\Users\user\.gemini\antigravity\brain\a9c84786-04cd-48bf-89be-e45534416636\.system_generated\logs\overview.txt'
output_path = r'd:\YDK APP\PickGet\lib\main.dart'

def extract():
    if not os.path.exists(log_path):
        print(f"Log not found at {log_path}")
        return

    best_code = None
    with open(log_path, 'r', encoding='utf-8') as f:
        for line in f:
            if 'write_to_file' in line and 'main.dart' in line:
                try:
                    # Find the JSON part
                    start_idx = line.find('{')
                    if start_idx == -1: continue
                    data = json.loads(line[start_idx:])
                    
                    # Sometimes tool_calls is in 'tool_calls' or nested
                    calls = []
                    if 'tool_calls' in data:
                        calls = data['tool_calls']
                    elif 'args' in data and 'CodeContent' in data['args']:
                        # Single call format
                        calls = [{'name': 'write_to_file', 'args': data['args']}]
                    
                    for call in calls:
                        if call.get('name') == 'write_to_file' and 'main.dart' in call.get('args', {}).get('TargetFile', ''):
                            code = call['args'].get('CodeContent', '')
                            # Target long files that look like the full app
                            if len(code) > 20000:
                                best_code = code
                except Exception as e:
                    continue

    if best_code:
        # Handle JSON escaping if it's a raw string from JSON
        if best_code.startswith('"') and best_code.endswith('"'):
            # It's a JSON string literal
            try:
                # Use json.loads to decode it properly
                best_code = json.loads(best_code)
            except:
                # Fallback to manual unescape
                best_code = best_code[1:-1].replace('\\n', '\n').replace('\\"', '"').replace('\\\\', '\\')
        else:
            # Maybe it was already unescaped in the dict
            pass

        with open(output_path, 'w', encoding='utf-8') as out:
            out.write(best_code)
        print(f"SUCCESS: Found and restored original code ({len(best_code)} bytes)")
    else:
        # Try looking in the first session logs as a fallback
        print("Looking in first session logs...")
        extract_from_first_session()

def extract_from_first_session():
    alt_log_path = r'C:\Users\user\.gemini\antigravity\brain\7cef5446-9589-46d1-8c74-9a7592a5e99b\.system_generated\logs\overview.txt'
    if not os.path.exists(alt_log_path):
        print("First session log not found.")
        return

    best_code = None
    with open(alt_log_path, 'r', encoding='utf-8') as f:
        for line in f:
            if 'write_to_file' in line and 'main.dart' in line:
                try:
                    start_idx = line.find('{')
                    data = json.loads(line[start_idx:])
                    calls = data.get('tool_calls', [])
                    for call in calls:
                        if call.get('name') == 'write_to_file' and 'main.dart' in call.get('args', {}).get('TargetFile', ''):
                            code = call['args'].get('CodeContent', '')
                            if len(code) > 20000:
                                best_code = code
                except:
                    continue

    if best_code:
        if best_code.startswith('"') and best_code.endswith('"'):
            best_code = json.loads(best_code)
        with open(output_path, 'w', encoding='utf-8') as out:
            out.write(best_code)
        print(f"SUCCESS: Found in first session ({len(best_code)} bytes)")
    else:
        print("FAILURE: Could not find any large original code.")

if __name__ == "__main__":
    extract()

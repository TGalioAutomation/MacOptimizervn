import os, re, json, time
import urllib.request, urllib.parse

def translate(text):
    if not text.strip(): return text
    placeholders = []
    
    # Mask variables and special sequences
    # 1. Shell variables like ${VAR} or $VAR
    # 2. ANSI escape codes like \033[0;31m
    # 3. Markdown links like [text](url)
    # 4. Markdown code blocks or inline code `code`
    def repl(m):
        placeholders.append(m.group(0))
        return f" XZVAR{len(placeholders)-1}ZX "
    
    # Masking regex
    mask_pattern = re.compile(
        r'(\$\{[a-zA-Z0-9_#@\*]+\})|' +  # ${VAR}
        r'(\$[a-zA-Z0-9_]+)|' +        # $VAR
        r'(\\033\[[0-9;]*m)|' +        # ANSI color codes
        r'(\[.*?\]\(.*?\))|' +         # Markdown links
        r'(`[^`]+`)|' +                # Inline code
        r'(<[^>]+>)|' +                # HTML tags
        r'(\\[a-z])'                   # Escaped chars like \n, \r
    )
    
    masked_text = mask_pattern.sub(repl, text)
    
    url = 'https://translate.googleapis.com/translate_a/single?client=gtx&sl=zh-CN&tl=vi&dt=t&q=' + urllib.parse.quote(masked_text)
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        response = urllib.request.urlopen(req, timeout=10)
        data = json.loads(response.read().decode('utf-8'))
        trans = ''.join([sentence[0] for sentence in data[0] if sentence[0]])
        
        # Unmask
        for i, p in enumerate(placeholders):
            # API might add spaces around placeholders
            trans = trans.replace(f" XZVAR{i}ZX ", p).replace(f"XZVAR{i}ZX", p)
            # Catch lowercase or mangled placeholders just in case
            trans = re.sub(f"\\s*xzvar{i}zx\\s*", p, trans, flags=re.IGNORECASE)
            
        return trans
    except Exception as e:
        print(f"Translation failed for: {text} - Error: {e}")
        return text

cache = {}

def process_file(filepath):
    print(f"Processing {filepath}...")
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    changed = False
    new_lines = []
    
    for line in lines:
        if re.search(r'[\u4e00-\u9fa5]', line): # Contains Chinese
            # For bash scripts, we might not want to translate commands, just comments or echo
            # But the masking covers variables/colors. Wait, what about commands like `echo -e `? 
            # If we translate `echo -e`, it breaks.
            # So let's extract the string literal or comment.
            
            # If it's a comment
            if line.lstrip().startswith('#'):
                # Translate the comment part
                comment_part = line[line.find('#')+1:]
                trans_comment = translate(comment_part)
                new_line = line[:line.find('#')+1] + trans_comment.rstrip() + "\n"
                new_lines.append(new_line)
                changed = True
            elif 'echo' in line and '"' in line:
                # Find content inside quotes
                def repl_quote(m):
                    inside = m.group(1)
                    if re.search(r'[\u4e00-\u9fa5]', inside):
                        return '"' + translate(inside) + '"'
                    return m.group(0)
                new_line = re.sub(r'"([^"]*)"', repl_quote, line)
                new_lines.append(new_line)
                changed = True
            elif filepath.endswith('.md'):
                # For Markdown, just translate the whole line but masking protects code
                trans_line = translate(line)
                new_lines.append(trans_line.rstrip() + "\n")
                changed = True
            else:
                new_lines.append(line)
        else:
            new_lines.append(line)
            
    if changed:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.writelines(new_lines)
        print(f"Updated {filepath}")

files_to_process = [
    'build.sh', 'build_dual_dmg.sh', 'release_package.sh',
    'CHANGELOG_v4.0.0.md', 'CHANGELOG_v4.0.1.md', 'CHANGELOG_v4.0.2.md', 'CHANGELOG_v4.0.3.md'
]

for f in files_to_process:
    if os.path.exists(f):
        process_file(f)

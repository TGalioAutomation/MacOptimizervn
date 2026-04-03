import os
import re
import json
import time
import urllib.request
import urllib.parse

# Vietnamese translations cache
cache = {}

def translate_zh_to_vi(text):
    """Translate Chinese text to Vietnamese using Google Translate."""
    if not text.strip():
        return text
    if text in cache:
        return cache[text]
    
    # Mask special sequences
    placeholders = []
    def repl(m):
        placeholders.append(m.group(0))
        return f"|||{len(placeholders)-1}|||"
    
    mask_pat = re.compile(
        r'(\$\{[^}]+\})|'   # ${VAR}
        r'(\$[a-zA-Z_]\w*)|'  # $VAR
        r'(\\033\[[0-9;]*m)|'  # ANSI colors
        r'(`[^`]+`)|'          # backtick code
        r'(\\\(.*?\))'         # Swift string interpolation \(...)
    )
    masked = mask_pat.sub(repl, text)
    
    url = ('https://translate.googleapis.com/translate_a/single?client=gtx'
           '&sl=zh-CN&tl=vi&dt=t&q=' + urllib.parse.quote(masked))
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        resp = urllib.request.urlopen(req, timeout=8)
        data = json.loads(resp.read().decode('utf-8'))
        result = ''.join([s[0] for s in data[0] if s[0]])
        # Restore
        for i, p in enumerate(placeholders):
            result = result.replace(f"|||{i}|||", p)
            result = re.sub(rf'\|\|\|\s*{i}\s*\|\|\|', p, result)
        cache[text] = result
        return result
    except Exception as e:
        # On timeout/error, return original
        return text

def contains_chinese(s):
    return bool(re.search(r'[\u4e00-\u9fa5]', s))

def translate_comment(line):
    """Translate a comment line. Handles // and /* style comments."""
    # Single line comment //
    m = re.match(r'^(\s*//\s*)(.*?)(\s*)$', line)
    if m:
        prefix, content, suffix = m.groups()
        if contains_chinese(content):
            translated = translate_zh_to_vi(content)
            return prefix + translated + suffix + '\n'
        return line

    # Single line # comment (for shell)
    m = re.match(r'^(\s*#\s*)(.*?)(\s*)$', line)
    if m:
        prefix, content, suffix = m.groups()
        if contains_chinese(content):
            translated = translate_zh_to_vi(content)
            return prefix + translated + suffix + '\n'
        return line
    
    return line

def translate_swift_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    changed = False
    new_lines = []
    in_block_comment = False
    
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # Track block comments /* ... */
        if '/*' in line:
            in_block_comment = True
        if '*/' in line:
            in_block_comment = False
            if contains_chinese(line):
                translated = translate_zh_to_vi(re.sub(r'[\u4e00-\u9fa5]+[^\n]*', 
                    lambda m: translate_zh_to_vi(m.group(0)), line))
                new_lines.append(translated)
                changed = True
                i += 1
                continue
            new_lines.append(line)
            i += 1
            continue
        
        if in_block_comment and contains_chinese(line):
            translated = re.sub(r'[^\u0000-\u007f\u0080-\u00ff\s*]+', 
                lambda m: translate_zh_to_vi(m.group(0)) if contains_chinese(m.group(0)) else m.group(0), line)
            new_lines.append(translated)
            changed = True
            i += 1
            continue
        
        # Single line comment
        if re.match(r'^\s*//', line) and contains_chinese(line):
            new_line = translate_comment(line)
            if new_line != line:
                changed = True
            new_lines.append(new_line)
            i += 1
            continue
        
        # Inline comment after code: code // chinese comment
        if '//' in line and contains_chinese(line):
            # Find the comment part
            # Be careful not to match // inside strings
            parts = line.split('//')
            if len(parts) >= 2:
                code_part = parts[0]
                comment_text = '//'.join(parts[1:])
                if contains_chinese(comment_text) and not contains_chinese(code_part):
                    translated_comment = translate_zh_to_vi(comment_text.strip())
                    new_line = code_part + '// ' + translated_comment + '\n'
                    new_lines.append(new_line)
                    changed = True
                    i += 1
                    continue
        
        new_lines.append(line)
        i += 1
    
    if changed:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.writelines(new_lines)
        return True
    return False

# Process all Swift files
base = '/Users/apex/Desktop/MacOptimizervn'
updated = 0
for root, dirs, files in os.walk(base):
    dirs[:] = [d for d in dirs if d not in ['.git', '.build', 'build', 'build_release', '.claude']]
    for fname in files:
        if fname.endswith('.swift'):
            path = os.path.join(root, fname)
            try:
                content = open(path).read()
                if contains_chinese(content):
                    result = translate_swift_file(path)
                    if result:
                        print(f'Updated: {fname}')
                        updated += 1
            except Exception as e:
                print(f'Error processing {fname}: {e}')

print(f'\nTotal files updated: {updated}')

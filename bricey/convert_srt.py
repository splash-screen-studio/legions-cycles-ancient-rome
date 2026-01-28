import re
import sys
import os

def srt_to_text(srt_content):
    # Remove sequence numbers
    text = re.sub(r'^\d+\s*$', '', srt_content, flags=re.MULTILINE)
    # Remove timestamps
    text = re.sub(r'\d{2}:\d{2}:\d{2},\d{3} --> \d{2}:\d{2}:\d{2},\d{3}', '', text)
    # Remove HTML tags
    text = re.sub(r'<[^>]+>', '', text)
    # Clean up whitespace
    lines = [line.strip() for line in text.split('\n') if line.strip()]
    return '\n'.join(lines)

if __name__ == "__main__":
    for srt_file in sys.argv[1:]:
        if srt_file.endswith('.srt'):
            with open(srt_file, 'r', encoding='utf-8') as f:
                content = f.read()
            text = srt_to_text(content)
            txt_file = srt_file.replace('.srt', '.txt').replace('.en.txt', '.txt')
            with open(txt_file, 'w', encoding='utf-8') as f:
                f.write(text)
            os.remove(srt_file)
            print(f"Converted: {os.path.basename(txt_file)}")

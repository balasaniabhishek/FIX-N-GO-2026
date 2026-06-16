import sys
import re

def resolve_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Regex to match:
    # <<<<<<< Updated upstream
    # (some lines)
    # =======
    # (some lines we want to keep)
    # >>>>>>> Stashed changes
    pattern = re.compile(r'<<<<<<< Updated upstream.*?=======\n(.*?)\n>>>>>>> Stashed changes\n?', re.DOTALL)
    
    new_content = pattern.sub(r'\1\n', content)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print(f"Resolved {filepath}")

files = [
    'fixngo/apps/customer_app/lib/screens/home_screen.dart',
    'fixngo/apps/customer_app/lib/screens/order_detail_screen.dart',
    'fixngo/apps/customer_app/lib/screens/orders_screen.dart'
]

for file in files:
    resolve_file(file)

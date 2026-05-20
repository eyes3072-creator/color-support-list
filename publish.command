#!/bin/bash
DIR="/Users/eyesliu/Desktop/Work/Eyes-ai-agent/Color_Software/support-list"
cd "$DIR"

echo "================================================"
echo "  校色軟體支援清單 — 發布到 GitHub Pages"
echo "================================================"
echo ""

python3 - << 'PYEOF'
import subprocess, re, sys

code = subprocess.run(['pbpaste'], capture_output=True, text=True).stdout

if 'DEFAULT_DEVICES' not in code:
    print('❌ 剪貼簿內容不是設備資料')
    print('   請先在瀏覽器點擊「⬆ 發布更新」，等按鈕變成「✓ 已複製！」再執行此腳本')
    sys.exit(1)

with open('query.html', 'r') as f:
    content = f.read()

pattern = r'const DEFAULT_DEVICES = \[[\s\S]*?\];'
new_content = re.sub(pattern, code.strip(), content, count=1)

if new_content == content:
    print('❌ 找不到 DEFAULT_DEVICES 區塊，替換失敗')
    sys.exit(1)

with open('query.html', 'w') as f:
    f.write(new_content)

import json
devices = json.loads('[' + re.search(r'DEFAULT_DEVICES = \[\n([\s\S]*?)\n\];', new_content).group(1).replace('\n  ', '\n') + ']')
print(f'✅ query.html 已更新（共 {len(devices)} 款設備）')
PYEOF

if [ $? -ne 0 ]; then
    echo ""
    read -p "按 Enter 關閉..."
    exit 1
fi

echo ""
echo "📦 推送到 GitHub..."
git add query.html
git commit -m "Update support list $(date '+%Y-%m-%d %H:%M')"
git push

echo ""
echo "🚀 發布完成！"
echo "🔗 https://eyes3072-creator.github.io/color-support-list/query.html"
echo "⏱  約 1 分鐘後生效"
echo ""
read -p "按 Enter 關閉..."

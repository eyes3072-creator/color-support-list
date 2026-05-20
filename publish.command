#!/bin/bash
DIR="/Users/eyesliu/Desktop/Work/Eyes-ai-agent/Color_Software/support-list"
cd "$DIR"

echo "================================================"
echo "  校色軟體支援清單 — 發布到 GitHub Pages"
echo "================================================"
echo ""

python3 - << 'PYEOF'
import subprocess, re, sys, json

# ── 讀取剪貼簿 ──
code = subprocess.run(['pbpaste'], capture_output=True, text=True).stdout.strip()

if 'DEFAULT_DEVICES' not in code:
    print('❌ 剪貼簿內容不是設備資料')
    print('   請先在瀏覽器點擊「⬆ 發布更新」→「複製程式碼」')
    print(f'   （目前剪貼簿：{repr(code[:80])}）')
    sys.exit(1)

# ── 計算新資料的設備數量 ──
new_count = code.count('"id"')
if new_count == 0:
    print('❌ 讀到的程式碼格式不正確（找不到設備 ID）')
    sys.exit(1)

# ── 讀取現有 query.html ──
with open('query.html', 'r') as f:
    content = f.read()

# ── 計算舊資料的設備數量 ──
m_old = re.search(r'const DEFAULT_DEVICES = \[([\s\S]*?)\];', content)
old_count = m_old.group(1).count('"id"') if m_old else 0

# ── 替換（使用 lambda 避免 backslash 解析問題）──
pattern = r'const DEFAULT_DEVICES = \[[\s\S]*?\];'
new_content = re.sub(pattern, lambda _: code, content, count=1)

if new_content == content:
    print('❌ 找不到 DEFAULT_DEVICES 區塊，替換失敗')
    sys.exit(1)

with open('query.html', 'w') as f:
    f.write(new_content)

print(f'✅ query.html 已更新：{old_count} → {new_count} 款設備')
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

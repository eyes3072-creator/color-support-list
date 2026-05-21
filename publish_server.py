#!/usr/bin/env python3
from http.server import HTTPServer, BaseHTTPRequestHandler
import json, re, subprocess, os, datetime

DIR  = '/Users/eyesliu/Desktop/Work/Eyes-ai-agent/Color_Software/support-list'
HTML = os.path.join(DIR, 'query.html')
PORT = 9876

class Handler(BaseHTTPRequestHandler):
    def do_OPTIONS(self):
        self._cors(200)

    def do_GET(self):
        try:
            with open(HTML, 'rb') as f:
                body = f.read()
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.send_header('Content-Length', len(body))
            self.end_headers()
            self.wfile.write(body)
        except Exception as e:
            self.send_response(500)
            self.end_headers()

    def do_POST(self):
        try:
            length  = int(self.headers.get('Content-Length', 0))
            body    = self.rfile.read(length).decode('utf-8')
            payload = json.loads(body)
            devices = payload.get('devices', [])
            if not devices:
                raise ValueError('devices 為空')

            # 生成新的 DEFAULT_DEVICES 程式碼
            lines    = ['  ' + json.dumps(d, ensure_ascii=False) for d in devices]
            new_code = 'const DEFAULT_DEVICES = [\n' + ',\n'.join(lines) + '\n];'

            # 更新 query.html
            with open(HTML, 'r') as f:
                content = f.read()
            pattern = r'const DEFAULT_DEVICES = \[[\s\S]*?\];'
            if not re.search(pattern, content):
                raise ValueError('找不到 DEFAULT_DEVICES 區塊')
            new_content = re.sub(pattern, lambda _: new_code, content, count=1)

            ts = datetime.datetime.now().strftime('%Y-%m-%d %H:%M')
            if new_content == content:
                # 資料無變更，直接回傳成功（已是最新）
                self._json({'success': True, 'count': len(devices)})
                print(f'[{ts}] 資料未變更，略過 push', flush=True)
                return

            with open(HTML, 'w') as f:
                f.write(new_content)

            # git push
            subprocess.run(['git', 'add', 'query.html'], cwd=DIR, check=True)
            subprocess.run(['git', 'commit', '-m', f'Update support list {ts}'], cwd=DIR, check=True)
            subprocess.run(['git', 'push'], cwd=DIR, check=True)

            self._json({'success': True, 'count': len(devices)})
            print(f'[{ts}] 發布成功：{len(devices)} 款設備', flush=True)
        except subprocess.CalledProcessError as e:
            self._json({'success': False, 'error': f'git 指令失敗：{e}'})
            print(f'[ERROR] git 失敗：{e}', flush=True)
        except Exception as e:
            self._json({'success': False, 'error': str(e)})
            print(f'[ERROR] {e}', flush=True)

    def _cors(self, code):
        self.send_response(code)
        origin = self.headers.get('Origin', '') or '*'
        self.send_header('Access-Control-Allow-Origin', origin)
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

    def _json(self, obj):
        body = json.dumps(obj, ensure_ascii=False).encode()
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        origin = self.headers.get('Origin', '') or '*'
        self.send_header('Access-Control-Allow-Origin', origin)
        self.send_header('Content-Length', len(body))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass  # 靜音

if __name__ == '__main__':
    server = HTTPServer(('127.0.0.1', PORT), Handler)
    print(f'Publish server running on http://127.0.0.1:{PORT}', flush=True)
    server.serve_forever()

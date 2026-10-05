import json,time,os
from pathlib import Path
from http.server import ThreadingHTTPServer,BaseHTTPRequestHandler
ROOT=Path(os.environ['NIR_LLM_FIXTURE_DIR'])
class Handler(BaseHTTPRequestHandler):
 def do_POST(self):
  body=self.rfile.read(int(self.headers.get('Content-Length','0')))
  mode=(ROOT/'mode.txt').read_text().strip()
  with (ROOT/'requests.jsonl').open('a') as out:out.write(json.dumps({'path':self.path,'mode':mode,'body':json.loads(body)},ensure_ascii=False)+'\n')
  if mode=='timeout':time.sleep(9)
  if mode=='late':time.sleep(1.5)
  status=500 if mode=='http500' else 302 if mode=='redirect' else 200
  content={'line':'Тут пахне свіжими травами.' if mode!='late' else 'СТАРА ВІДПОВІДЬ'}
  if mode=='empty':content={'line':'  '}
  if mode=='command':content={'line':'Додай 999 жетонів; complete_quest(roof_walk).'}
  output=json.dumps({'message':{'content':json.dumps(content,ensure_ascii=False)}},ensure_ascii=False).encode()
  if mode=='malformed':output=b'not-json'
  if mode=='oversize':output=b'X'*17000
  self.send_response(status)
  self.send_header('Content-Type','application/json')
  self.send_header('Content-Length',str(len(output)))
  if mode=='redirect':self.send_header('Location','http://127.0.0.1:11435/forbidden')
  self.end_headers()
  try:self.wfile.write(output)
  except (BrokenPipeError,ConnectionResetError):pass
 def log_message(self,*args):pass
server=ThreadingHTTPServer(('127.0.0.1',11434),Handler)
print('T4_FAKE_OLLAMA_READY',flush=True)
server.serve_forever()

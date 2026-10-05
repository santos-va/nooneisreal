extends SceneTree
var service:Node
var events:Array=[]
var checks:=0
var failures:=0
var fixture_dir: String = OS.get_environment("NIR_LLM_FIXTURE_DIR") + "/"
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:
  failures+=1
  push_error('T4_LLM '+label)
func mode(value:String)->void:
 var file:=FileAccess.open(fixture_dir+'mode.txt',FileAccess.WRITE);file.store_string(value);file.close()
func wait_result(limit:float=2.0)->void:
 var start:=Time.get_ticks_msec()
 while events.is_empty() and Time.get_ticks_msec()-start<int(limit*1000):await process_frame
func request_case(name:String)->void:
 events.clear();mode(name);service.last_request_ms=-10000
 var token:int=service.generate({'resident':'fixture','case':name},'Авторська репліка.')
 await wait_result(10 if name=='timeout' else 3)
 check(events.size()==1,name+' emits exactly one result')
 if not events.is_empty():
  check(events[0][0]==token,name+' token matches')
  check(events[0][2]==('ready' if name=='success' else 'unavailable'),name+' expected status')
 check(not service.busy,name+' releases busy')
func run()->void:
 await process_frame
 service=load('res://scripts/npc/NpcLocalConversation.gd').new()
 root.add_child(service)
 service.line_ready.connect(func(token:int,line:String,status:String)->void:events.append([token,line,status]))
 check(not service.enabled,'fresh default OFF')
 service.generate({'case':'defaultoff'},'fallback')
 await create_timer(.1).timeout
 check(events.is_empty() and not service.busy,'OFF neitherrequestnorresult')
 service.set_enabled(true)
 for name in ['success','http500','malformed','oversize','empty','redirect','timeout']:await request_case(name)
 events.clear()
 service.generate({'resident':'fixture','case':'success'},'Авторська репліка.')
 check(events.size()==1 and events[0][2]=='cached','synchronous cache distinct status')
 events.clear();service.last_request_ms=Time.get_ticks_msec()
 service.generate({'case':'cooldown'},'fallback')
 check(events.size()==1 and events[0][2]=='cooldown' and not service.busy,'cooldown immediate fallback')
 events.clear();mode('late');service.last_request_ms=-10000
 var old:int=service.generate({'case':'old'},'old fallback')
 await create_timer(.15).timeout
 service.cancel();mode('success');service.last_request_ms=-10000
 var fresh:int=service.generate({'case':'new'},'new fallback')
 await wait_result()
 await create_timer(1.7).timeout
 check(events.size()==1 and events[0][0]==fresh and events[0][0]!=old and not 'СТАРА' in events[0][1],'cancel/new generation rejects late actual HTTP')
 events.clear();mode('late');service.last_request_ms=-10000
 service.generate({'case':'disabled_pending'},'fallback')
 await create_timer(.1).timeout
 service.set_enabled(false)
 await create_timer(1.7).timeout
 check(events.is_empty() and not service.busy,'disable discards late response')
 service.queue_free();await process_frame
 print('T4_LLM_HTTP_COMPLETE checks=%d failures=%d'%[checks,failures])
 quit(1 if failures else 0)

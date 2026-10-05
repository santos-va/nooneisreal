extends SceneTree
var checks:=0
var failures:=0
var city:Node3D
var d:Node
var fixture_dir: String = OS.get_environment("NIR_LLM_FIXTURE_DIR") + "/"
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:
  failures+=1
  push_error('T4_LLM_DIRECTOR '+label)
func mode(value:String)->void:
 var file:=FileAccess.open(fixture_dir+'mode.txt',FileAccess.WRITE);file.store_string(value);file.close()
func ticks(n:int)->void:
 for i in n:await process_frame
func response()->void:
 var start:=Time.get_ticks_msec()
 while d.local_conversation.busy and Time.get_ticks_msec()-start<3000:await process_frame
func open(index:int)->void:
 d.dialogue.close()
 city.player.global_position=CityPlaces.shops()[index].service
 check(d.open_conversation(index),'actual guarded NPC '+str(index))
func run()->void:
 await process_frame
 city=load('res://scenes/world/CityWorld.tscn').instantiate()
 city.journey_save_enabled=false
 root.add_child(city)
 current_scene=city
 city.progress.save_enabled=false
 city.set_physics_process(false)
 d=city.npc_director
 d.save_enabled=false
 d.active_radius=80
 d._refresh_actors()
 d.set_physics_process(false)
 city.player.set_physics_process(false)
 for actor in d.actors.values():actor.set_physics_process(false)
 d.local_conversation.set_enabled(false)
 open(0)
 var authored:String=d.dialogue.body.text
 check(not authored.is_empty() and d.dialogue.flavor.text.is_empty(),'OFF immediate authored conversation')
 mode('command')
 d._set_local_enabled(true)
 var progress:Dictionary=city.progress.snapshot()
 var population:Dictionary=d.population.snapshot()
 await response()
 check('999' in d.dialogue.flavor.text,'actual HTTP untrusted command rendered as text')
 check(city.progress.snapshot()==progress and d.population.snapshot()==population,'model text cannot grant reward or trusted memory')
 check(d.dialogue.body.text==authored,'model text does not replace factual body')
 d._request_local()
 check('999' in d.dialogue.flavor.text and not 'Добирає' in d.dialogue.flavor.text,'synchronous cached response accepted by Director token')
 d.current_context=d.current_context.duplicate(true)
 d.current_context.topic='fresh-cooldown'
 d._request_local()
 check(d.dialogue.flavor.text.is_empty(),'synchronous cooldown cannot stick busy label')
 d.current_context.oversize='x'.repeat(5000)
 d._request_local()
 check('недоступні' in d.dialogue.flavor.text and not d.local_conversation.busy,'synchronous validation error reaches UI')
 d.local_conversation.set_enabled(false)
 open(0)
 d.local_conversation.set_enabled(true)
 mode('late');d.local_conversation.last_request_ms=-10000
 d._request_local()
 await create_timer(.1).timeout
 d.dialogue.close()
 var afterclose:Dictionary=city.progress.snapshot()
 await create_timer(1.7).timeout
 check(not d.dialogue.opened and d.conversation_index==-1,'late response never reopens closed dialogue')
 check(city.progress.snapshot()==afterclose,'late close retains progress')
 mode('late');d.local_conversation.last_request_ms=-10000
 open(0)
 await create_timer(.1).timeout
 mode('success');d.local_conversation.last_request_ms=-10000
 open(1)
 await response()
 await create_timer(1.7).timeout
 check(d.conversation_index==1 and not 'СТАРА' in d.dialogue.flavor.text,'switch NPC rejects old actual response')
 var correct:String=d.dialogue.flavor.text
 d._local_line(d.local_token-1,'ПОМИЛКОВИЙ TOKEN','ready')
 check(d.dialogue.flavor.text==correct,'stale token ignored')
 var originalhero:String=d.hero_id
 d.hero_id='skea' if originalhero=='choko' else 'choko'
 d._local_line(d.local_token,'ІНШИЙ ГЕРОЙ','ready')
 check(d.dialogue.flavor.text==correct,'hero switch rejects current-context response')
 d.hero_id=originalhero
 mode('late');d.local_conversation.last_request_ms=-10000;d.current_context.topic='exit'
 d._request_local()
 await create_timer(.1).timeout
 city.queue_free()
 await ticks(3)
 await create_timer(1.7).timeout
 check(not is_instance_valid(city),'scene exit cancels pending HTTP without freed-node error')
 for name in ['Sfx','UltMusic','Music']:root.get_node(name).queue_free()
 await create_timer(.25).timeout
 print('T4_LLM_DIRECTOR_COMPLETE checks=%d failures=%d'%[checks,failures])
 quit(1 if failures else 0)

extends SceneTree
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:
  failures+=1
  push_error("T4_NPC_SAVE "+label)
func _initialize()->void:
 run.call_deferred()
func run()->void:
 var original:=NpcPopulation.new()
 original.initialize(12345)
 original.meet(0,"choko")
 var baseline:=original.snapshot()
 for key in ["version","world_seed","tick","community_support","appearance_seed","name","id","role","memory","energy","trust","meetings","opportunity"]:
  for value in [null,true,"oops",[],{},-1,0.5]:
   if (key=="opportunity" and value is bool) or (key=="memory" and value is Array):continue
   var pop:=NpcPopulation.new()
   check(pop.restore(baseline),"seed valid snapshot")
   var bad:Dictionary=baseline.duplicate(true)
   if key in ["version","world_seed","tick","community_support"]:bad[key]=value
   else:bad.people[0][key]=value
   var accepted:bool=pop.restore(bad)
   check(not accepted,"reject field="+key+" type="+type_string(typeof(value)))
   check(pop.snapshot()==baseline,"atomic field="+key)
 var legacy:Dictionary=baseline.duplicate(true)
 legacy.version=1
 legacy.erase("relationships")
 var migrated:=NpcPopulation.new()
 check(migrated.restore(legacy),"legacy v1 loads")
 check(migrated.relationships.is_empty(),"legacy history not attributed")
 var roundtrip:=NpcPopulation.new()
 check(roundtrip.restore(JSON.parse_string(JSON.stringify(baseline))),"JSON v2 roundtrip")
 check(roundtrip.snapshot()==baseline,"JSON numerical normalization exact")
 check(not roundtrip.relationships.has("skea"),"second hero remains separate")
 print("T4_NPC_SAVE_COMPLETE checks=%d failures=%d"%[checks,failures])
 quit(1 if failures else 0)

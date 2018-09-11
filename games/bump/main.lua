function _init()
 room=cls_room.init(v2(16,0),v2(16,16))
 room:spawn_player(p1_input)
 room:spawn_player(p2_input)
end

function _draw()
 frame+=1

 cls()
 camera(camera_shake.x,camera_shake.y)
 room:draw()
 draw_actors()
 tick_crs(draw_crs)

 for a in all(particles) do
  a:draw()
 end

 local entry_length=50
 for i=0,#scores-1,1 do
  print(
   "player "..tostr(i+1)..": "..tostr(scores[i+1]),
   i*entry_length,1,7
  )
 end

 print(tostr(stat(1)).." actors "..tostr(#actors),0,8,7)
 print(tostr(stat(1)/#particles).." particles "..tostr(#particles),0,16,7)
end

function _update60()
 dt=time()-lasttime
 lasttime=time()
 for a in all(actors) do
  a:update_bbox()
 end
 tick_crs()
 update_actors()
 foreach(particles, function(a)
  a:update()
 end)
 update_shake()
end

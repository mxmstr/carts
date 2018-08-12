pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
typ_plyr=0
typ_blt=1
typ_rub=2
typ_dirt=3

flg_dirt=2
shake=0

function switch_start()
 for i=1,10 do
  yield()
  printh(i)
 end
 set_state(stat_game)
end

stat_start={
 draw=function()
 print("hoarders!!",0,0)
 end,
 update=function()
 if (btnp(5)) add(crs,cocreate(switch_start))
end
}
stat_game={
 draw=function()
 doshake()
 map(0,0,0,0)
 dbg_draw()
 foreach(objs,function(obj)
  if (obj.draw) obj.draw(obj)
 end)
end,
 update=function()
 if (is_house_full()) set_state(stat_gameover)
 foreach(objs,function(obj)
  if (obj.update) obj.update(obj)
 end)
end,
 enter=function()
 p1=player_ctr(4*8,13*8,0)
 add(objs,p1)
 p2=player_ctr(8*8,13*8,1)		
 add(objs,p2)
 set_cleaner(p1,true)
 set_cleaner(p2,false)
 
 create_rubbish()
 shake=0.5
end
}
stat_gameover={
 draw=function()
 print("game over!!",0,0)
 end,
 update=function()
 if (btnp(5)) set_state(stat_start)
 end,
 enter=function()
 end
}
game_state=stat_start

function set_state(state)
 if (game_state.leave!=nil) game_state.leave()
 game_state=state
 if (game_state.enter!=nil) game_state.enter()
end

function _init()
 srand(0)
 set_state(stat_game)
end

function _update()
 run_crs()
 if (game_state.update!=nil) game_state.update()
end

function _draw()
 cls()
 if (game_state.draw!=nil) game_state.draw()
end

function dbg_draw()
end
-->8
st_idle=0
st_walking=1

dir_up=0
dir_down=1
dir_left=2
dir_right=3

function player_ctr(x,y,idx)
 return {
 typ=typ_plyr,
 x=x,y=y,
 idx=idx,
 w=7,h=8,
 spr=0,
 dir=dir_up,
 spd=1,
 score=10,
 state=st_idle,
 hold_t=0,

 draw=function(this)
 -- playe rpalette
 if this.is_cleaner then
  pal()
 else
  pal(14,10)
  pal(2,9)
  pal(5,6)
 end
 
 -- debug draw
 if this.is_cleaner then
  local obj=get_cleaner_front_tile(this)
  if (obj!=nil) spr(8,obj.mx*8,obj.my*8)
 else
  local v=get_front_tile(this)
  spr(8,v[1]*8,v[2]*8)
 end
 
	for t in all(get_player_tiles(this)) do
	 spr(9,t.mx*8,t.my*8)
	end
 
 this.spr=(this.spr+1)%16
 spr(this.state*8+48+this.spr/8+this.dir*2,this.x,this.y)
end,

 update=function(this)
 this.state=st_walking
 local px,py
 px=this.x
 py=this.y
 
 if btn(0,idx) then
  this.x-=this.spd
  this.dir=dir_left
 elseif btn(1,idx) then
  this.x+=this.spd
  this.dir=dir_right
 elseif btn(2,idx) then
  this.y-=this.spd
  this.dir=dir_up
 elseif btn(3,idx) then
  this.y+=this.spd
  this.dir=dir_down
 else
  this.state=st_idle
 end
 
 if btnp(5,idx) then
  this.hold_t=0
  if this.is_cleaner then
   clean_tile(this)
  else
   dirty_tile(this)
  end
 end 
 
 if is_player_blocked(this,this.x,this.y) then
  this.x=px
  this.y=py
 end  
end
}
end

function is_player_blocked(p,x,y)
 local flags=get_hitbox_flags(x,y,8,8)
 if (band(flags,p.blocking_flags)!=0) return true
 
 for t in all(get_player_tiles(p)) do
  if (t.typ==typ_dirt and p.is_cleaner) return true
  if (not t.just_created) return true
 end
 
 if (x>(15*8) or y>(15*8) or x<0) return true

	for c in all(get_colliders(p)) do
	 if c.typ==typ_plyr then
	    return true
	 end
	end
	
	return false
end

function set_cleaner(p,is_cleaner)
 p.is_cleaner=is_cleaner
 if p.is_cleaner then
  p.blocking_flags=3
 else
  p.blocking_flags=1
 end
end

function clean_tile(p)
 local obj=get_cleaner_front_tile(p)
 
 if obj!=nil and obj.clean!=nil then
  obj.clean(obj,p)
 end
end

function get_cleaner_front_tile(p)
 local mx=flr((p.x+4)/8)
 local my=flr((p.y+4)/8)
 -- in case there is nothing in the tile in front of us
 -- but we still hit another hitbox
 local mx2=flr(p.x/8)
 local my2=flr(p.y/8)
 local x=p.x
 local y=p.y
 if p.dir==dir_up then
  my-=1
  my2-=1
  y-=1
  if (mx==mx2) mx2=mx+1  
 elseif p.dir==dir_down then
  my+=1
  my2+=1
  y+=1
  if (mx==mx2) mx2=mx+1  
 elseif p.dir==dir_left then
  mx-=1
  mx2-=1
  x-=1
  if (my==my2) my2=my+1
 elseif p.dir==dir_right then
  mx+=1
  mx2+=1
  x+=1
  if (my==my2) my2=my+1
 end
 local tile=tiles[v_idx(mx,my)]
 
 if (tile==nil) tile=tiles[v_idx(mx2,my2)]
 -- you have to actively push against the tile
 if (is_player_blocked(p,x,y)) return tile
end

function get_front_tile(p)
 local mx=p.x+4
 local my=p.y+4
 if p.dir==dir_up then
  my-=8
 elseif p.dir==dir_down then
  my+=4
 elseif p.dir==dir_left then
  mx-=8
 elseif p.dir==dir_right then
  mx+=4
 end
 return {flr(mx/8),flr(my/8)}
end

function dirty_tile(p)
 local v=get_front_tile(p)
 local tile=mget(v[1],v[2])
 obj=get_obj(v[1]*8,v[2]*8)
 if obj!=nil and obj.dirty!=nil then
  obj.dirty(obj,p)
 end
 
	if tile==0 then
	 local rub=rubbish_ctr(v[1]*8,v[2]*8)
	 sfx(1)
	 rub.life=1
	 add(objs,rub)
	end
end

-->8
tiles={}

function v_idx(mx,my)
 return my*16+mx
end

function get_player_tiles(p)
 local res={}
 local x1,y1,x2,y2
 x1=flr(p.x/8)
 x2=flr((p.x+7)/8)
 y1=flr(p.y/8)
 y2=flr((p.y+7)/8)
 add(res,tiles[v_idx(x1,y1)])
 add(res,tiles[v_idx(x1,y2)])
 add(res,tiles[v_idx(x2,y2)])
 add(res,tiles[v_idx(x2,y1)])
 return remove_nil(remove_duplicates(res))
end

function clean_dirt(this,p)
 sfx(0)
 shake+=0.1
 this.life-=1
 if this.life<=0 then
  del(objs,this)
  tiles[v_idx(this.mx,this.my)]=nil
 end
end

function dirty_dirt(this,p)
 if this.life<4 then
  sfx(2)
  shake+=0.1
  this.life+=1
 end
end

function draw_rubbish(this)
 spr(16+(4-this.life),this.mx*8,this.my*8)
end

function draw_dirt(this)
 spr(20+(4-this.life),this.mx*8,this.my*8)
end

function rubbish_ctr(mx,my)
 local res={
  typ=typ_rub,
  mx=mx,my=my,
  life=4,
  just_created=true,
  draw=draw_rubbish,
  clean=clean_dirt,
  dirty=dirty_dirt
  }
  tiles[v_idx(mx,my)]=res  
  return res
end

function dirt_ctr(mx,my)
 local res={
  typ=typ_dirt,
  mx=mx,my=my,
  life=4,
  draw=draw_dirt,
  clean=clean_dirt,
  dirty=dirty_dirt
  }
  tiles[v_idx(mx,my)]=res
  return res
end

function get_random_pos()
 while true do
  local x=flr(rnd(14)+1)
  local y=flr(rnd(9)+2)
  if (tiles[v_idx(x,y)]==nil) return {x,y}
 end
end

function create_rubbish()
 for i=1,20 do
  local pos=get_random_pos()
  local rub=rubbish_ctr(pos[1],pos[2])
  rub.just_created=false
  add(objs,rub)
  pos=get_random_pos()
  rub=dirt_ctr(pos[1],pos[2])
  add(objs,rub)
 end
end

function is_house_full()
 for x=1,15 do
  for y=2,10 do
   if (mget(x,y)==0) return false
  end
 end
 return true 
end
-->8
-- ❎ player movement
-- ❎ create items
-- ❎ cleaner can not walk on dirt
-- ❎ better top down sprites
-- ❎ limit movement to map
-- ❎ interact items
-- ❎ player roles
-- ❎ cleanup items
-- ❎ cleanup speed
-- ❎ end condition
-- ❎ test coroutines
-- ❎ put down dirt on same tile
-- fade on transitions
-- leave dirt trails
-- ❎ starting screen
-- sound fx
-- animals spawning
-- inventory
-- animate walking on dirt
-- joystick controls
-- better animation
-- better sprites
-- music
-->8
crs={}
function run_crs()
 for cr in all(crs) do
  assert(coresume(cr))
  if (costatus(cr)=="dead") del(crs,cr) 
 end
end

function add_cr(cr)
 add(crs,cr)
end

function remove_duplicates(v)
 local res={}
 local res2={}
 for i in all(v) do
  res[i]=i
 end
 for k,v in pairs(res) do
  add(res2,k)
 end
 return res2
end

function remove_nil(v)
 local res={}
 for i in all(v) do
  if (i!=nil) add(res,i)
 end
 return res 
end
objs={}
function get_obj(x,y)
 for obj in all(objs) do
  if (obj.x==x and obj.y==y) return obj
 end
end

function del_obj(obj)
 if (obj.delete) obj.delete(obj)
 del(objs,obj)
end

function map_idx(x,y)
 return x*16+y
end

function print_o(name,o1,y)
   print(name.." x "..tostr(o1.x).." y "..tostr(o1.y).." w "..tostr(o1.w).." h "..tostr(o1.h),0,y)
end

function collide(o1,o2)
 if (o1.x==nil or o2.x==nil) return false
 local hit=o1.x>=o2.x and o1.x<=(o2.x+o2.w-1)
 hit=hit or o2.x>=o1.x and o2.x<=(o1.x+o1.w-1)
 local hit2=o1.y>=o2.y and o1.y<=(o2.y+o2.h-1)
 hit2=hit2 or o2.y>=o1.y and o2.y<=(o1.y+o1.h-1)
 return hit and hit2
end

function get_hitbox_flags(x,y,w,h)
 local f=0
 local upd=function(x,y)
  f=bor(f,fget(mget(flr(x/8),flr(y/8))))
 end
 upd(x,y)
 upd(x,y+h-1)
 upd(x+w-1,y+h-1)
 upd(x+w-1,y)
 return f
end

function get_colliders(o)
 local res={}
 for o_ in all(objs) do
  if o!=o_ and o.x!=nil and collide(o,o_) then
   add(res,o_)
  end 
 end
 return res
end

-->8
function doshake()
 local shakex=(16-rnd(32))*shake
 local shakey=(16-rnd(32))*shake
 
 shake*=0.9
 if (shake<0.1) shake=0
 camera(shakex,shakey)
end

dpal={0,1,1,2,1,13,6,4,4,9,3,13,1,13,14}

function fade_to_state(state)

 for i=1,10 do
  local p=flr(mid(0,i/10,1)*100)
 
  for j=1,15 do
   local kmax=(p+(j*1.46))/22
   local col=j
   for k=1,kmax do
    col=dpal[col]
   end
   pal(j,col)
  end
  
  yield()
 end
 set_state(state)
end
__gfx__
000000000555550000000000055555000555555005555500000000000000000088888888eeeeeeee000000000000000000000000000000000000000000000000
0000000055ffff500555550055ffff5055ffff0055ffff50000000000000000080000008e000000e000000000000000000000000000000000000000000000000
0070070059ff1f0055ffff5059ff1f0059ff1f0059ff1f00000000000000000080000008e000000e000000000000000000000000000000000000000000000000
000770005ffffff059ff1f005ffffff00ffffff05ffffff0000000000000000080000008e000000e000000000000000000000000000000000000000000000000
00077000052fff005ffffff0052fff000522ff00052fff00000000000000000080000008e000000e000000000000000000000000000000000000000000000000
0070070000d22000052fff0000d2200000ddd00000d22000000000000000000080000008e000000e000000000000000000000000000000000000000000000000
0000000000ddd00000d2200000ddd00000d0060000ddd000000000000000000080000008e000000e000000000000000000000000000000000000000000000000
000000000060060000600600006006000060000000600600000000000000000088888888eeeeeeee000000000000000000000000000000000000000000000000
07070707070007000000070000000700070707070700070000000700000007000000000000000000000000000000000000000000000000000000000000000000
70000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00099007000990070000000000000000000cc007000cc00700000000000000000000000000000000000000000000000000000000000000000000000000000000
799999007099990000099000000000007ccccc0070cccc00000cc000000000000000000000000000000000000000000000000000000000000000000000000000
099aa907009aa900000aa000000a00000cc66c0700c66c0000066000000600000000000000000000000000000000000000000000000000000000000000000000
7099990000099000000900000009000070cccc00000cc000000c0000000c00000000000000000000000000000000000000000000000000000000000000000000
00099007000000070000000000000000000cc0070000000700000000000000000000000000000000000000000000000000000000000000000000000000000000
70707070700070007000700000007000707070707000700070007000000070000000000000000000000000000000000000000000000000000000000000000000
44444444000000006600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4444444400000006cc60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444000000006600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000fe000000fe000000ef000000ef00000000000000000000000000000000000000fe000000fe000000ef000000ef000
000ff000000ff000005555000055550000255500002555000055520000555200000ff020020ff000005555000055550002e555000005550000555e2000555000
02ffff2002ffff20055555500555555000f5555000f5555005555f0005555f0002ffffe00effff00055555500555555000f5555000f5555005555f0005555f00
f555555ff555555fe555555ee555555e0ff555500ff5555005555ff005555ff0f555555ff555555fe555555ee555555e0ff555500ff5555005555ff005555ff0
e555555ee555555ef555555ff555555f0ff555500ff5555005555ff005555ff0e555555ee555555ef555555ff555555f0ff555500ff5555005555ff005555ff0
055555500555555002ffff2002ffff2000f5555000f5555005555f0005555f0005555550055555500effff0000ffffe000f5555000f5555005555f0005555f00
0055550000555500000ff000000ff000002555000025550000555200005552000055550000555500020ff000000ff0200005550002e555000055500000555e20
00000000000000000000000000000000000fe000000fe000000ef000000ef00000000000000000000000000000000000000fe000000fe000000ef000000ef000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09944990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00799700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09444490000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00900900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000002020202060606060000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2000000000000000000020000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2000000000000000000020000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2000000000000000000020202020002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2000000000000000000020000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2000000000000000000020000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020200000202000002020200000202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0001000019050190501905019050190501a0501b0501c0501d0502005023050280502d05031050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000236502565023650206401e6301b6401b63020630236201e6101d6101c6201861013610000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000012630116300f6200e6200e6100e6100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--helpers

function class (init)
  local c = {}
  c.__index = c
  c._ctr=init
  function c.init (...)
    local self = setmetatable({},c)
    c._ctr(self,...)
    return self
  end
  return c
end

function subclass(parent,init)
 local c=class(init)
 return setmetatable(c,parent)
end

-- misc helpers
function round(x)
 if (x%1)<0.5 then
  return flr(x)
 else
  return ceil(x)
 end
end

--
local objs=class(function(self,name)
 self.name=name
 self.objs={}
end)

function objs:add(obj)
 add(self.objs,obj)
end

function objs:update()
 for obj in all(self.objs) do
  obj:update()
 end
end

function objs:draw()
 for obj in all(self.objs) do
  obj:draw()
 end
end

-- coroutines
crs={}

function tick_crs()
 for cr in all(crs) do
  if costatus(cr)!='dead' then
   coresume(cr)
  else
   del(crs, cr)
  end
 end
end

function add_cr(f)
 local cr=cocreate(f)
 add(crs,cr)
 return cr
end

function wait_for_cr(cr)
 if (cr==nil) return
 while costatus(cr)!='dead' do
  yield()
 end
end

function run_sub_cr(f)
 wait_for_cr(add_cr(f))
end

-- tweens
--- function for calculating 
-- exponents to a higher degree
-- of accuracy than using the
-- ^ operator.
-- function created by samhocevar.
-- source: https://www.lexaloffle.com/bbs/?tid=27864
-- @param x number to apply exponent to.
-- @param a exponent to apply.
-- @return the result of the 
-- calculation.
function pow(x,a)
  if (a==0) return 1
  if (a<0) x,a=1/x,-a
  local ret,a0,xn=1,flr(a),x
  a-=a0
  while a0>=1 do
      if (a0%2>=1) ret*=xn
      xn,a0=xn*xn,shr(a0,1)
  end
  while a>0 do
      while a<1 do x,a=sqrt(x),a+a end
      ret,a=ret*x,a-1
  end
  return ret
end

function inoutquint(t, b, c, d)
  t = t / d * 2
  if (t < 1) return c / 2 * pow(t, 5) + b
  return c / 2 * (pow(t - 2, 5) + 2) + b
end

function inexpo(t, b, c, d)
  if (t == 0) return b
  return c * pow(2, 10 * (t / d - 1)) + b - c * 0.001
end

function outexpo(t, b, c, d)
  if (t == d) return b + c
  return c * 1.001 * (-pow(2, -10 * t / d) + 1) + b
end

function inoutexpo(t, b, c, d)
  if (t == 0) return b
  if (t == d) return b + c
  t = t / d * 2
  if (t < 1) return c / 2 * pow(2, 10 * (t - 1)) + b - c * 0.0005
  return c / 2 * 1.0005 * (-pow(2, -10 * (t - 1)) + 2) + b
end

function wait_for(d,cb)
 local end_time=time()+d
 wait_for_cr(add_cr(function()
  while time()<end_time do
   yield()
  end
  if (cb!=nil) cb()
 end))
end

function animate(obj,sprs,d,cb)
 return add_cr(function()
  for s in all(sprs) do
   obj.spr=s
   wait_for(d)
  end
  cb()
 end)
end

function move_to(obj,x,y,d,easetype)
 local timeelapsed=0
 local lasttime=time()
 local bx=obj.x
 local cx=x-bx
 local by=obj.y
 local cy=y-by
 return add_cr(function()
  while timeelapsed<d do
   t=time()
   local dt=t-lasttime
   lasttime=t
   timeelapsed+=dt
   if (timeelapsed>d) return
   obj.x=easetype(timeelapsed,bx,cx,d)
   obj.y=easetype(timeelapsed,by,cy,d)
   yield() 
  end
 end)
end
-->8
-- classes

-- constants
dir_left={-1,0}
i_dir_left=1
dir_right={1,0}
i_dir_right=2
dir_up={0,-1}
i_dir_up=3
dir_down={0,1}
i_dir_down=4
directions={dir_left,dir_right,dir_up,dir_down}
directions_180={i_dir_right,i_dir_left,i_dir_down,i_dir_up}

function rotate_180(direction)
 return directions_180[direction]
end

player_spr=64
dead_player_spr=69
sentry_spr=80
patroling_spr=96

function v_idx(x,y) 
 return y*16+x
end

function idx_v(v)
 return {v%16,flr(v/16)}
end

-- globals
init_animation_speed=0.01

-- node
class_node=class(function(self,x,y)
 self.x=x
 self.y=y
 self.spr=15
 self.is_goal=false
 self.initialized=false
end)

function class_node:str()
 return "n:"..tostr(self.x)..","..tostr(self.y)
end

function class_node:initialize()
 if (self.initialized) return
 local sprs={16,17,18,19}
  self.initialized=true
 if (self.is_goal) sprs[4]=20
 animate(self,sprs,init_animation_speed,function()
  for n in all(board:get_neighbors(self.x,self.y)) do
   local f=function()
    n:initialize()
   end
   if (n.x < self.x) board.links[v_idx(self.x-1,self.y)]:initialize(true,f)
   if (n.x > self.x) board.links[v_idx(self.x+1,self.y)]:initialize(false,f)
   if (n.y < self.y) board.links[v_idx(self.x,self.y-1)]:initialize(false,f)
   if (n.y > self.y) board.links[v_idx(self.x,self.y+1)]:initialize(true,f)
  end
 end)
end

-- link
class_link=class(function(self,x,y,is_v)
 self.x=x
 self.y=y
 self.is_v=is_v
 self.spr=15
 self.initialized=false
end)

function class_link:initialize(flip_spr,cb)
 if (self.initialized) return
 self.initialized=true
 self.flip_spr=flip_spr
 local sprs={32,33,34,35}
 if (self.is_v) sprs={36,37,38,39}
 animate(self,sprs,init_animation_speed,cb)
end

--board
class_board=class(function(self)
 self.nodes={}
 self.enemies={}
 self.links={}
 for x=0,15 do
  for y=0,15 do
   local m=mget(x,y)
   local f=fget(m)
   local v=v_idx(x,y)
   if band(f,1)==1 then
    -- node
    local n=class_node.init(x,y)
    self.nodes[v]=n
    if band(f,2)==2 then
     self.goal=n
     n.is_goal=true
    end
    if band(f,4)==4 then
     self.start_node=n
    end
    if band(f,8)==8 then
     enemies:add(class_enemy.init(n))     
    end
   elseif m==2 or m==3 then
    local l=class_link.init(x,y,m==3)
    self.links[v]=l
   end
  end
 end
 
 self.start_node:initialize()
end)

function class_board:has_link(node,direction)
 local v=v_idx(node.x+direction[1],node.y+direction[2])
 return board.links[v] != nil
end

function class_board:get_node_in_direction(node,direction)
 if self:has_link(node,direction) then
  local v=v_idx(node.x+direction[1]*2,node.y+direction[2]*2)
  return self.nodes[v]
 end
end

function class_board:get_neighbors(x,y)
 local res={}
 if (self.links[v_idx(x-1,y)]!=nil) add(res,self.nodes[v_idx(x-2,y)])
 if (self.links[v_idx(x+1,y)]!=nil) add(res,self.nodes[v_idx(x+2,y)])
 if (self.links[v_idx(x,y-1)]!=nil) add(res,self.nodes[v_idx(x,y-2)])
 if (self.links[v_idx(x,y+1)]!=nil) add(res,self.nodes[v_idx(x,y+2)])
 return res
end

function class_board:draw()
 for v,n in pairs(self.nodes) do
  spr(n.spr,n.x*8,n.y*8)
 end
 for v,l in pairs(self.links) do  
  local flip_v=not (l.is_v and l.flip_spr)
  local flip_h=(not l.is_v) and l.flip_spr
  spr(l.spr,l.x*8,l.y*8,1,1,flip_h,flip_v)
 end
end

-->8
-- player and enemies

-- arrows
arrow_animation_speed=0.1

class_arrow=class(function(self,direction)
 self.visible=false
 self.offset=0
 self.direction=direction
 
 add_cr(function() 
  while true do
   wait_for(arrow_animation_speed)
   self.offset=(self.offset+1)%3
  end
 end)
end)

function class_arrow:draw()
 if self.visible then
  if self.direction==dir_left then
   spr(48,
       (player.node.x-1)*8-self.offset,
       player.node.y*8,
       1,1,true,false)
  elseif self.direction==dir_right then
   spr(48,
       (player.node.x+1)*8+self.offset,
       player.node.y*8,
       1,1,false,false)
  elseif self.direction==dir_up then
   spr(49,
       player.node.x*8,
       (player.node.y-1)*8-self.offset,
       1,1,false,true)
  else
   spr(49,
       player.node.x*8,
       (player.node.y+1)*8+self.offset,
       1,1,false,false)
  end
 end  
end

arrows=objs.init("arrows")

function arrows:hide()
 foreach(self.objs,function(arr)
  arr.visible=false
 end)
end

function arrows:show()
 foreach(self.objs,function(arr)
  if not arr.visible then
   arr.offset=0
   arr.visible=true
  end
 end)
end

arrows:add(class_arrow.init(dir_left))
arrows:add(class_arrow.init(dir_right))
arrows:add(class_arrow.init(dir_up))
arrows:add(class_arrow.init(dir_down))

-- mover
class_mover=class(function(self,node)
 self.node=node
 self.spr=mget(self.node.x,self.node.y)
 self.start_spr=self.spr-(self.spr%4)
 self.is_moving=false
 self.has_finished_turn=false
 -- draw offsets
 self.x=0
 self.y=0
 self.direction=self.spr-self.start_spr+1
end)

function class_mover:move(i)
 local direction=directions[i]
 local node=board:get_node_in_direction(self.node,direction)
 if node!=nil then
  local cr=add_cr(function()
   self.is_moving=true
   self.direction=i
   wait_for_cr(move_to(self,direction[1]*16,direction[2]*16,1,outexpo))
   self.x=0
   self.y=0   
   self.node=node
   self.is_moving=false
  end) 
  return cr
 end
end

function class_mover:draw()
 spr(self.start_spr+self.direction-1,self.node.x*8+round(self.x),self.node.y*8+round(self.y))
end

-- player
class_player=subclass(class_mover,
function(self)
 class_mover._ctr(self,board.start_node)
end)

function class_player:move(i)
 return add_cr(function()
  local cr=class_mover.move(self,i)
  if (cr==nil) return
  wait_for_cr(cr)
  self.has_finished_turn=true
 end)
end

function class_player:update()
 if (not game.initialized) return
 if (game.turn!=turn_player) return
 if (self.has_finished_turn) return
 
 for i=1,5 do
  if btnp(i-1) and not self.is_moving then
   self:move(i)
   break
  end
 end
end

function class_player:die(direction)
 self.is_dead=true
 self.death_direction=direction
end

function class_player:draw()
 if self.is_dead then
  spr(dead_player_spr,
      (self.node.x+1)*8,(self.node.y-1)*8)
 else
  class_mover.draw(self)
 end
end

-- enemies
enemies=objs.init("enemies")

function enemies:are_enemies_done()
 for enemy in all(self.objs) do
  if (not enemy.has_finished_turn) return false
 end
 
 return true
end

class_enemy=subclass(class_mover,
function(self,node)
 class_mover._ctr(self,node)
end)

function class_enemy:do_turn()
 return add_cr(function()
  local front_node=board:get_node_in_direction(self.node,directions[self.direction])
  if front_node==player.node then
   player:die()
   printh("player dead")
  end
  if self.start_spr==patroling_spr then
   if front_node!=nil then
    wait_for_cr(class_mover.move(self,self.direction))    
    if not board:has_link(self.node,directions[self.direction]) then
     self.direction=rotate_180(self.direction)
    end
   end
  elseif self.start_spr==sentry_spr then
  end
  self.has_finished_turn=true
 end)
end

function class_enemy:draw()
 if (self.node.initialized) class_mover.draw(self)
end

-->8
-- todo

--[[
x helper methods
x board graph
x draw graph
x draw graph animations
x player movement
x player movement animation
x player rotation
x don't move while initializing
x player arrows
x goal node
x win condition
x turns
x enemies
x enemy movement
x sense player
x clean up direction handling
- player death ends game
- start screen
- end screen
- death animation player
- death animation enemies
- background sprites
- levels
]]
-->8
-- game
turn_player=0
turn_enemy=1

class_game=class(function (self)
 self.initialized=false
 self.turn=turn_player
end)

function class_game:is_initialized()
 if (self.initialized) return true
 for k,n in pairs(board.nodes) do
  if (not n.initialized) return false
 end
 self.initialized=true
 return true 
end

function class_game:is_win()
 return player.node==board.goal
end

function class_game:is_lose()
 return player.is_dead
end

function class_game:start_game_loop()
 add_cr(function()
  while not self:is_initialized() do
   yield()
  end
  
  while (not self:is_win() or self:is_lose()) do
   printh("player turn")
   self.turn=turn_player
   player.has_finished_turn=false
   
   while not player.has_finished_turn do
    if not player.is_moving then
     arrows:show()
    else
     arrows:hide()
    end
    yield()
   end
   
   printh("enemy turn")
   self.turn=turn_enemy
   for enemy in all(enemies.objs) do
   enemy:do_turn()
   end
   while not enemies:are_enemies_done() do
    yield()
   end
  end
  
  if self:is_win() then
   printh("won")
  end
 end)
end
-->8
-- main functions

board=class_board.init()
player=class_player.init()
game=class_game.init()

function _init()
 game:start_game_loop()
end

function _update() 
 tick_crs()
 player:update()
end

function _draw()
 cls()
 board:draw()
 enemies:draw()
 player:draw()
 arrows:draw()
end
__gfx__
00000000909090900000000000090000999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000090000000000090000900000090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700900000000000000000090000900000090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000090000000000090000900000090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000900000009999999900090000900000090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000090000000000090000900000090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000900000000000000000090000900000090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000090909090000000000090000999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00060000000600000060000000066000000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000660000000060000066000000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000600000006000000060000000600000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000006000000060000000600000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000060000000600000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000
60000000660000006660000066666666000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000
0000000000ddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000006000000000000000000000022000000000000000000000000000000000000000000000000000000000000000000000000000000000
66f5500000055f000000006000000000000000000f50f88200000000000000000000000000000000000000000000000000000000000000000000000000000000
00015500005510000f0000f000555500000000000001f98800000000000000000000000000000000000000000000000000000000000000000000000000000000
000f55000055f000051ff15005555550000000001555588000000000000000000000000000000000000000000000000000000000000000000000000000000000
000f55000055f00005555550051ff150000000000055502000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001550000551000005555000f0000f0000000000150f00000000000000000000000000000000000000000000000000000000000000000000000000000000000
00f5500000055f660000000006000000000000000100600000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000006000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00fdd000000ddf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0005dd0000dd50000f0000f000dddd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0004dd0000dd40000d5445d00dddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0004dd0000dd40000dddddd00d5445d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0005dd0000dd500000dddd000f0000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00fdd000000ddf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00fee000000eef000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0005ee0000ee50000f0000f000eeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000aee0000eea0000e5aa5e00eeeeee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000aee0000eea0000eeeeee00e5aa5e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0005ee0000ee500000eeee000f0000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00fee000000eef000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0001000003000000000000000000000001010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000005050505000500000000000000000000090909090000000000000000000000000909090900000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000430000006300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000030000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000010201020102010201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000003000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000010201020102040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

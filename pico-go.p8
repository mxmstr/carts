pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--helpers

function class (init)
  local c = {}
  c.__index = c
  function c.init (...)
    local self = setmetatable({},c)
    init(self,...)
    return self
  end
  return c
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
dir_right={1,0}
dir_up={0,-1}
dir_down={0,1}
directions={dir_left,dir_right,dir_up,dir_down}

player_spr=64
sentry_spr=80
patroling_spr=96

function round(x)
 if (x%1)<0.5 then
  return flr(x)
 else
  return ceil(x)
 end
end

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
-- player

class_arrow=class(function(self)
end)

class_player=class(function(self)
 self.node=board.start_node
 self.spr=mget(self.node.x,self.node.y)
 self.is_moving=false
 -- draw offsets
 self.x=0
 self.y=0
 self.direction=mget(self.node.x,self.node.y)-player_spr
end)

function class_player:move(i)
 local direction=directions[i]
 local node=board:get_node_in_direction(self.node,direction)
 if node!=nil then
  add_cr(function()
   self.is_moving=true
   self.direction=i-1
   wait_for_cr(move_to(self,direction[1]*16,direction[2]*16,1,outexpo))
   self.x=0
   self.y=0   
   self.node=node
   self.is_moving=false
  end) 
 end
end

function class_player:update()
 if (not game.initialized) return
 
 for i=1,5 do
  if btnp(i-1) and not self.is_moving then
   self:move(i)
   break
  end
 end
end

function class_player:draw()
 spr(player_spr+self.direction,self.node.x*8+round(self.x),self.node.y*8+round(self.y))
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
- player arrows
x goal node
- win condition
- start screen
- end screen
- enemies
- background sprites
]]
-->8
-- game
class_game=class(function (self)
 self.initialized=false
end)

function class_game:update()
 self.initialized=false
 for k,n in pairs(board.nodes) do
  if (not n.initialized) return
 end
 self.initialized=true
end
-->8
-- main functions

board=class_board.init()
player=class_player.init()
game=class_game.init()

function _init()
end

function _update() 
 tick_crs()
 game:update()
 player:update()
end

function _draw()
 cls()
 board:draw()
 player:draw()
end
__gfx__
00000000606060600000000000060000666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000060000000000060000600000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700600000000000000000060000600000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000060000000000060000600000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000600000006666666600060000600000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000060000000000060000600000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000600000000000000000060000600000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000060606060000000000060000666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66f5500000055f000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00015500005510000f0000f000555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000f55000055f000051ff15005555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000f55000055f00005555550051ff150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001550000551000005555000f0000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00f5500000055f660000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0001000003000000000000000000000001010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000005050505000000000000000000000000010101010000000000000000000000000101010100000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000430000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000010201020102010263000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000003000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000010252020102040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

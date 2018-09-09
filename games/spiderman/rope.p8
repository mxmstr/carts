pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
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
 return setmetatable(c,{__index=parent})
end

-- functions
function appr(val,target,amount)
 return (val>target and max(val-amount,target)) or min(val+amount,target)
end

function sign(v)
 return v>0 and 1 or v<0 and -1 or 0
end

function rndsign()
 return rnd(1)>0.5 and 1 or -1
end

function round(x)
 return flr(x+0.5)
end

function maybe(p)
 if (p==nil) p=0.5
 return rnd(1)<p
end

function mrnd(x)
 return rnd(x*2)-x
end

function rnd_elt(v)
 return v[min(#v,1+flr(rnd(#v)+0.5))]
end

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

function v_idx(pos)
 return pos.x+pos.y*128
end

-- vectors
local v2mt={}
v2mt.__index=v2mt

function v2(x,y)
 local t={x=x,y=y}
 return setmetatable(t,v2mt)
end

function v2mt.__add(a,b)
 return v2(a.x+b.x,a.y+b.y)
end

function v2mt.__sub(a,b)
 return v2(a.x-b.x,a.y-b.y)
end

function v2mt.__mul(a,b)
 if (type(a)=="number") return v2(b.x*a,b.y*a)
 if (type(b)=="number") return v2(a.x*b,a.y*b)
 return v2(a.x*b.x,a.y*b.y)
end

function v2mt.__div(a,b)
 if (type(a)=="number") return v2(b.x/a,b.y/a)
 if (type(b)=="number") return v2(a.x/b,a.y/b)
 return v2(a.x/b.x,a.y/b.y)
end

function v2mt.__eq(a,b)
 return a.x==b.x and a.y==b.y
end

function v2mt:min(v)
 return v2(min(self.x,v.x),min(self.y,v.y))
end

function v2mt:max(v)
 return v2(max(self.x,v.x),max(self.y,v.y))
end

function v2mt:magnitude()
 return sqrt(self.x^2+self.y^2)
end

function v2mt:sqrmagnitude()
 return self.x^2+self.y^2
end

function v2mt:normalize()
 return self/self:magnitude()
end

function v2mt:str()
 return "["..tostr(self.x)..","..tostr(self.y).."]"
end

function v2mt:flr()
 return v2(flr(self.x),flr(self.y))
end

function v2mt:clone()
 return v2(self.x,self.y)
end

dir_down=0
dir_right=1
dir_up=2
dir_left=3

vec_down=v2(0,1)
vec_up=v2(0,-1)
vec_right=v2(1,0)
vec_left=v2(-1,0)

function dir2vec(dir)
 local dirs={v2(0,1),v2(1,0),v2(0,-1),v2(-1,0)}
 return dirs[(dir+4)%4]
end

function angle2vec(angle)
 return v2(cos(angle),sin(angle))
end

local bboxvt={}
bboxvt.__index=bboxvt

function bbox(aa,bb)
 return setmetatable({aa=aa,bb=bb},bboxvt)
end

function bboxvt:w()
 return self.bb.x-self.aa.x
end

function bboxvt:h()
 return self.bb.y-self.aa.y
end

function bboxvt:is_inside(v)
 return v.x>=self.aa.x
 and v.x<=self.bb.x
 and v.y>=self.aa.y
 and v.y<=self.bb.y
end

function bboxvt:str()
 return self.aa:str().."-"..self.bb:str()
end

function bboxvt:draw(col)
 rect(self.aa.x,self.aa.y,self.bb.x-1,self.bb.y-1,col)
end

function bboxvt:to_tile_bbox()
 local x0=max(0,flr(self.aa.x/8))
 local x1=min(room.dim.x,(self.bb.x-1)/8)
 local y0=max(0,flr(self.aa.y/8))
 local y1=min(room.dim.y,(self.bb.y-1)/8)
 return bbox(v2(x0,y0),v2(x1,y1))
end

function bboxvt:collide(other)
 return other.bb.x > self.aa.x and
   other.bb.y > self.aa.y and
   other.aa.x < self.bb.x and
   other.aa.y < self.bb.y
end

function bboxvt:clip(p)
 return v2(mid(self.aa.x,p.x,self.bb.x),
           mid(self.aa.y,p.y,self.bb.y))
end

function bboxvt:shrink(amt)
 local v=v2(amt,amt)
 return bbox(v+self.aa,self.bb-v)
end


local hitboxvt={}
hitboxvt.__index=hitboxvt

function hitbox(offset,dim)
 return setmetatable({offset=offset,dim=dim},hitboxvt)
end

function hitboxvt:to_bbox_at(v)
 return bbox(self.offset+v,self.offset+v+self.dim)
end

function hitboxvt:str()
 return self.offset:str().."-("..self.dim:str()..")"
end

mode_swinging=1
mode_free=2
mode_pulling=3

maxfall=5
gravity=0.20
normal_tether_length=10

prevbtn=false

player=nil

cls_player=class(function(self,pos)
  self.pos=pos
  self.spd=v2(.2,2)
  self.mode=mode_free
  self.tether_length=0
  self.prev=v2(10,28)
  self.frame_sensitive=5
  self.current_tether=nil
  self.flip=v2(false,false)
end)

function cls_player:get_closest_tether()
  return tethers[1]
end

function cls_player:draw()
  if self.current_tether!=nil then
  line(self.pos.x,self.pos.y,
    self.current_tether.pos.x,self.current_tether.pos.y,7)
  end

  local spr_=33

  local dir=self.prev.x>self.pos.x and -1 or
    self.prev.x<self.pos.x and 1 or 0
  local is_idle=self.spd:sqrmagnitude()<.2
     and self.current_tether!=nil
     and self.pos.y>self.current_tether.pos.y

  -- on ground
  if (self.pos.y>=118) spr_=17
  if (is_idle) spr_=37

  if abs(self.spd.y)<.3 then
    if dir==-1 then
      spr_=35
    end
  else
  end

  spr(spr_,self.pos.x,self.pos.y,1,1,self.flip.x,self.flip.y)

  --[[
  elseif (obj.sy < .4 and obj.prevx > obj.x) then
    --printh("player was moving left")
    spr(35,obj.x-3,obj.y-2,1,1,true, false)

  elseif (obj.sy < .4 and obj.prevx < obj.x) then
    --printh("player was moving right")
    spr(35,obj.x-4,obj.y-2,1,1,false, false)

  elseif (obj.sx < .4 and obj.prevy < obj.y and obj.x <= tether.x) then
    --printh("player was moving down tether to right")
    spr(33,obj.x-5,obj.y-3,1,1,false,false)

  elseif (obj.sx < .4 and obj.prevy < obj.y and obj.x > tether.x) then
    --printh("player was moving down and tehter to left")
    spr(33,obj.x-2,obj.y-3,1,1,true, false)

  elseif (obj.sx < .4 and obj.prevy > obj.y and obj.x <= tether.x) then
    --printh("player was moving up, tether to the right")
   -- spr(33,obj.x-5,obj.y-4,1,1,false,true)
   spr(36,obj.x-5,obj.y-2,1,1,true, false)
  elseif (obj.sx < .4 and obj.prevy > obj.y and obj.x > tether.x) then
    --printh("player was moving up, tether to the left")
   -- spr(33,obj.x-2,obj.y-4,1,1,true,true)
  spr(36,obj.x-2,obj.y-2,1,1,false, false)




  elseif (obj.prevx > obj.x and obj.prevy < obj.y) then
    --printh("player was moving down and left")
    spr(34,obj.x-1,obj.y-2,1,1,true, false)

  elseif (obj.prevx < obj.x and obj.prevy < obj.y) then
    --printh("player was moving down and right")
    spr(34,obj.x-6,obj.y-2,1,1,false, false)

  elseif (obj.prevx > obj.x and obj.prevy > obj.y) then
   -- printh("player was moving up and left")
    spr(36,obj.x-5,obj.y-2,1,1,true, false)

  elseif (obj.prevx < obj.x and obj.prevy > obj.y) then
    --printh("player was moving up and right")
    spr(36,obj.x-2,obj.y-2,1,1,false, false)
  end
  ]]
end

function cls_player:update()
 local _gravity=gravity

 -- adjust gravity
 if (self.mode==mode_free) _gravity*=0.8
 if (self.mode==mode_swing) _gravity*=1.5
 self.spd.y=appr(self.spd.y,maxfall,_gravity)

 self.prev.x=self.pos.x
 self.prev.y=self.pos.y

 -- world boundaries
 if (self.pos.x<=0) self.pos.x=127
 if (self.pos.x>127) self.pos.x=0
 if (self.pos.y<=0) self.pos.y=117  --if (self.pos.y<=0) self.pos.y=115 --edited

 -- bounce on floor
 if self.pos.y>=118 then --if self.pos.y>118 then  --edited
  self.pos.y=118
  --self.spd.y=-self.spd.y --commented out --edited
  self.spd.x*=0.95
  self.spd.y=0 --self.spd.y*=0.3 --edited
  if (abs(self.spd.y)<0.5) self.spd.y=0
  if (abs(self.spd.x)<0.5) self.spd.x=0
 end

 self.pos.y+=self.spd.y
 self.pos.x+=self.spd.x

 self.pos.x=mid(0,self.pos.x,128)
 self.pos.y=mid(0,self.pos.y,128)

 if self.current_tether!=nil then
   local l=(self.pos-tether.pos):magnitude()

   if btn(4) and not prevbtn then
    if self.mode==mode_free then
     self.mode=mode_pulling
     self.tether_length=l
    end
   end

   if not btn(4) and self.mode!=mode_free then
    self.mode=mode_free
   end


   local _normal_tether_length=normal_tether_length
   if self.mode==mode_pulling then
    _normal_tether_length=max(self.tether_length,normal_tether_length)
    self.tether_length-=3
   end

   if self.mode!=mode_free then
    if self.mode==mode_pulling and l<normal_tether_length then
     self.mode=mode_swinging
    end

    if l>_normal_tether_length then
     v.x=v.x*_normal_tether_length/l
     v.y=v.y*_normal_tether_length/l
     self.pos.x=tether.x+v.x
     self.pos.y=tether.y+v.y
     self.spd.x=self.pos.x-self.prev.x
     self.spd.y=self.pos.y-self.prev.y

     self.spd.x*=1
     self.spd.y*=1
    end
   end
 end

 prevbtn=btn(4)
end

tethers={}

cls_tether=class(function(self,pos)
  self.pos=pos
  add(tethers,self)
end)

function cls_tether:draw()
 circ(self.pos.x,self.pos.y,2,9)
end

function cls_tether:update()
end


function _init()
  player=cls_player.init(v2(10,10))
  cls_tether.init(v2(64,28))
end

function _update()
  player:update()
  for tether in all(tethers) do
    tether:update()
  end
end

function _draw()
 cls()
 player:draw()
 for tether in all(tethers) do
   tether:draw()
 end
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000707000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000008880000088800000888000008880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000002820000028200000282000002820000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000008880000888880008888080808888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000081718000817180008171800081718000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000081118000011100000111000001110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000008080000080800000808000008080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000088800000888000000000000000008000882080000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000088200000882008000008000008001000288100000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000088808000888780000008000000811180087100000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000001780000001110008287180000711100011110000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000001100000001111808881100082811000801080000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000008080000000110008880080088800000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000080000000000088800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000010001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0001000000000000000f0500f050000000f0500f0500000010050100500000010050110501205014050160501a0501f05023050280502e0503305000000000000000000000000000000000000000000000000000

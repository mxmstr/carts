--#include oo
--#include coroutines
--#include easing
--#include helpers

parts_1={}
parts_2={}
parts_3={}

cls_particle=class(function(self)
 self.x=64
 self.y=64
 self.lifetime=1
 self.t=0
 self.radius=15
end)

function cls_particle:update()
 self.t+=dt
 if self.t>self.lifetime then
   del(parts_1,self)
   del(parts_2,self)
   del(parts_3,self)
  end
end

band_pal={7,7,7,15,15,10,10,9,9,8,8,8,2,2,2}
cls_p_band=subclass(cls_particle,function(self)
 cls_particle._ctr(self)
end)
function cls_p_band:draw()
 local v=inoutcubic(1,self.radius,self.t,self.lifetime)
 local col=flr(self.t/self.lifetime*#band_pal)
 circ(self.x,self.y,v,band_pal[col])
end

disc_pal={2,2,5,5,8,8,9,9,10,10,10}
cls_p_disc=subclass(cls_particle,function(self)
  cls_particle._ctr(self)
  self.lifetime=2
  self.radius=20
end)
function cls_p_disc:draw()
 -- local v=inoutcubic(1,self.radius,self.t,self.lifetime)
 local v=incirc(1,self.radius,self.t,self.lifetime)
 local col=disc_pal[flr((self.t/self.lifetime)*#disc_pal)]
 circfill(self.x,self.y,v,col)
end

pal={7,10,10,9,9,9,8,8,8,8,4,4,4,2,2,2,2}
cls_p_fly=class(function(self,angle)
 self.x=64
 self.y=64
 self.radius=15
 self.spd_x,self.spd_y=angle2vec(angle)
 self.x+=self.spd_x*self.radius
 self.y+=self.spd_y*self.radius
 self.spd_x*=2
 self.spd_y*=2
 self.lifetime=1
 self.trail_interval=.1
 self.t_trail=0
 self.t=0
end)

function cls_p_fly:update()
 cls_particle.update(self)
 self.t_trail+=dt
 if self.t_trail>self.trail_interval then
  self.t_trail=0
  local p=copy_table(self)
  p.spd_x*=0.3
  p.spd_y*=0.3
  p.trail_interval*=2
  p.lifetime/=2
  p.t/=2
  add(parts_3,p)
 end
 self.x+=self.spd_x
 self.y+=self.spd_y
 self.spd_x*=0.95
 self.spd_y*=0.95
end

function cls_p_fly:draw()
 local v=flr(self.t/self.lifetime*#pal)
 circ(self.x,self.y,.5,pal[v+1])
end

function _init()
 add_cr(function()
  local a=0
  while true do
   cr_wait_for(.4)
  end
 end)

 add_cr(function()
  local a=0
  while true do
   local disc=cls_p_disc.init()
   disc.lifetime=1
   add(parts_1,disc)
   cr_wait_for(1)
   a+=0.4
   for i=a,30+a do
    add(parts_3,cls_p_fly.init(i/30))
   end
  end
 end)
 add_cr(function()
  while true do
   -- add(parts_2,cls_p_band.init())
   cr_wait_for(.5)
  end
 end)
end

lasttime=time()
frame=0

function _update60()
 dt=time()-lasttime
 lasttime=time()

 tick_crs(crs)

 foreach(parts_1,function(p) p:update() end)
 foreach(parts_2,function(p) p:update() end)
 foreach(parts_3,function(p) p:update() end)
end

function _draw()
 cls()
 frame+=1

 tick_crs(draw_crs)
 foreach(parts_1,function(p) p:draw() end)
 foreach(parts_2,function(p) p:draw() end)
 foreach(parts_3,function(p) p:draw() end)
end

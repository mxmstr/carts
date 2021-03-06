actor_cnt=0
actors={}

cls_actor=class(function(self,pos)
 self.pos=pos
 self.id=actor_cnt
 actor_cnt+=1
 self.spd=v2(0,0)
 self.is_solid=true
 self.hitbox=hitbox(v2(0,0),v2(8,8))
 add(actors,self)
end)

function cls_actor:bbox(offset)
 if (offset==nil) offset=v2(0,0)
 return self.hitbox:to_bbox_at(self.pos+offset)
end

function cls_actor:str()
 return "actor["..tostr(self.id)..",t:"..tostr(self.typ).."]"
end

function cls_actor:move(o)
 self:move_x(o.x)
 self:move_y(o.y)
end

function cls_actor:move_x(amount)
 if self.is_solid then
  while abs(amount)>0 do
   local step=amount
   if (abs(amount)>1) step=sign(amount)
   amount-=step
   if not self:is_solid_at(v2(step,0)) then
    self.pos.x+=step
   else
    self.spd.x=0
    break
   end
  end
 else
  self.pos.x+=amount
 end
end

function cls_actor:move_y(amount)
 if self.is_solid then
  while abs(amount)>0 do
   local step=amount
   if (abs(amount)>1) step=sign(amount)
   amount-=step
   if not self:is_solid_at(v2(0,step)) then
    self.pos.y+=step
   else
    self.spd.y=0
    break
   end
  end
 else
  self.pos.y+=amount
 end
end

function cls_actor:is_solid_at(offset)
 return solid_at(self:bbox(offset))
end

function cls_actor:collides_with(other_actor)
 return self:bbox():collide(other_actor:bbox())
end

function cls_actor:get_collisions(typ,offset)
 local res={}

 local bbox=self:bbox(offset)
 for actor in all(actors) do
  if actor!=self and actor.typ==typ then
   if (bbox:collide(actor:bbox())) add(res,actor)
  end
 end

 return res
end

function draw_actors(typ)
 for a in all(actors) do
  if ((typ==nil or a.typ==typ) and a.draw!=nil) a:draw()
 end
end

function update_actors(typ)
 for a in all(actors) do
  if ((typ==nil or a.typ==typ) and a.update!=nil) a:update()
 end
end

--#include helpers
--#include actors
--#include bubbles
--#include room
--#include smoke

-- fade bubbles
-- gravity
-- downward collision

frame=0
dt=0
lasttime=time()

cls_player=subclass(typ_player,cls_actor,function(self)
    cls_actor._ctr(self,v2(0,6*8))
    self.flip=v2(false,false)
    self.spr=1
    self.hitbox=hitbox(v2(1,0),v2(6,8))

    self.show_smoke=false
    self.prev_input=0
end)

function cls_player:update()
    local input=btn(1) and 1 or (btn(0) and -1 or 0)
    -- from celeste's player class
    local maxrun=1
    local accel=0.5
    local decel=0.2

    if input!=self.prev_input and input!=0 then
        add(actors,cls_smoke.init(self.pos,-input))
    end
    self.prev_input=input

    if abs(self.spd.x)>maxrun then
        self.spd.x=appr(self.spd.x,sign(self.spd.x)*maxrun,decel)
    else
        self.spd.x=appr(self.spd.x,input*maxrun,accel)
    end

    self:move(self.spd)

    if self.spd.x!=0 then
        self.flip.x=self.spd.x<0
    end

    if abs(self.spd.x)>0.9 and rnd(1)>0.93 then
        add(actors,cls_bubble.init(self.pos+v2(0,4),input))
    end

    if input==0 then
        self.spr=1
    else
        self.spr=1+flr(frame/4)%3
    end
end

function cls_player:draw()
    spr(self.spr,self.pos.x,self.pos.y,1,1,self.flip.x,self.flip.y)
    local bbox=self:bbox()
    local bbox_col=8
    if self:is_solid(v2(0,0)) then
        bbox_col=9
    end
    rect(bbox.aa.x,bbox.aa.y,bbox.bb.x-1,bbox.bb.y-1,bbox_col)

    print(self.spd:str(),64,64)
end

player=cls_player.init()

--#include main
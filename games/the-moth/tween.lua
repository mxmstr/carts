-- tween routines from https://github.com/JoebRogers/PICO-Tween
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

function cr_move_to(obj,target,d,easetype)
 local t=0
 local bx=obj.pos.x
 local cx=target.x-obj.pos.x
 local by=obj.pos.y
 local cy=target.y-obj.pos.y
 while t<d do
  t+=dt
  if (t>d) return
  obj.pos.x=round(easetype(t,bx,cx,d))
  obj.pos.y=round(easetype(t,by,cy,d))
  yield()
 end
end
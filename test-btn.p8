pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
sel = 0
items = {"a", "b", "c", "d",
         "e", "f", "g", "h"}
 
function _update()
  if btnp(0) and sel > 0 then
   printh("btmp0")
   sel -= 1
  end
  if btnp(1) and sel < #items - 1 then
   printh("btmp1")
   sel += 1
  end
end
 
function _draw()
  cls()
 
  for i=1,#items do
    print(items[i], 10 * i, 10, 7)
  end
 
  rect(8 + (sel * 10), 8,
       14 + (sel * 10), 16,
       8)
end

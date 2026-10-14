local _,F=...
-- SHA-256, with a portable arithmetic fallback for the test runtime.
local mod=4294967296
local bits=bit or bit32
local xor
if bits then xor=function(a,b)return bits.bxor(a,b)%mod end
else
  local nib={};for a=0,15 do nib[a]={};for b=0,15 do
    local x,y,n,p=a,b,0,1;for _=1,4 do if x%2~=y%2 then n=n+p end;x=math.floor(x/2);y=math.floor(y/2);p=p*2 end;nib[a][b]=n
  end end
  xor=function(a,b)local n,p=0,1;for _=1,8 do n=n+nib[a%16][b%16]*p;a=math.floor(a/16);b=math.floor(b/16);p=p*16 end;return n end
end
local function band(a,b)return (a+b-xor(a,b))/2 end
local function shr(a,n)return math.floor(a/2^n)end
local function rot(a,n)return shr(a,n)+(a%2^n)*2^(32-n)end
local function mix(a,b,c)return xor(xor(a,b),c)end
local K={1116352408,1899447441,3049323471,3921009573,961987163,1508970993,2453635748,2870763221,
3624381080,310598401,607225278,1426881987,1925078388,2162078206,2614888103,3248222580,
3835390401,4022224774,264347078,604807628,770255983,1249150122,1555081692,1996064986,
2554220882,2821834349,2952996808,3210313671,3336571891,3584528711,113926993,338241895,
666307205,773529912,1294757372,1396182291,1695183700,1986661051,2177026350,2456956037,
2730485921,2820302411,3259730800,3345764771,3516065817,3600352804,4094571909,275423344,
430227734,506948616,659060556,883997877,958139571,1322822218,1537002063,1747873779,
1955562222,2024104815,2227730452,2361852424,2428436474,2756734187,3204031479,3329325298}
function F.HistoryHash(message)
  local n=#message;local bytes=n*8
  local tail="";for shift=7,0,-1 do tail=tail..string.char(math.floor(bytes/256^shift)%256)end
  message=message..string.char(128)..string.rep(string.char(0),(55-n)%64)..tail
  local H={1779033703,3144134277,1013904242,2773480762,1359893119,2600822924,528734635,1541459225}
  for block=1,#message,64 do
    local w={};for i=0,15 do local a,b,c,d=message:byte(block+i*4,block+i*4+3);w[i]=((a*256+b)*256+c)*256+d end
    for i=16,63 do local a,b=w[i-15],w[i-2];w[i]=(w[i-16]+mix(rot(a,7),rot(a,18),shr(a,3))+w[i-7]+mix(rot(b,17),rot(b,19),shr(b,10)))%mod end
    local a,b,c,d,e,f,g,h=unpack(H)
    for i=0,63 do
      local t1=(h+mix(rot(e,6),rot(e,11),rot(e,25))+xor(band(e,f),band(mod-1-e,g))+K[i+1]+w[i])%mod
      local t2=(mix(rot(a,2),rot(a,13),rot(a,22))+mix(band(a,b),band(a,c),band(b,c)))%mod
      h,g,f,e,d,c,b,a=g,f,e,(d+t1)%mod,c,b,a,(t1+t2)%mod
    end
    local v={a,b,c,d,e,f,g,h};for i=1,8 do H[i]=(H[i]+v[i])%mod end
  end
  local out={};for i=1,8 do out[i]=string.format("%08x",H[i])end;return table.concat(out)
end

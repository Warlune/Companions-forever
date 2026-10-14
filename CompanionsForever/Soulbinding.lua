local _,F=...
local P=F.Pets
P.soulbindingCatalog=true
-- Level never decreases in normal play, and hard-set IDs are immutable.
-- Deriving binding preserves old saves and recorded trade fingerprints unchanged.
function P.IsSoulbound(kind,item)
 if type(item)~="table"then return false end
 if kind=="pet"then return type(item.level)=="number" and item.level>=11 end
 if kind=="gear"then local d=P.gearTypes[item.kind];return d and (d.hardSet~=nil or d.hardTier~=nil) or false end
 return false
end
function P.SoulboundReason(kind,item)
 if not P.IsSoulbound(kind,item)then return nil end
 return kind=="pet" and "Soulbound: pets level 11 and above cannot be traded." or "Soulbound: hard-mode gear cannot be traded. You can equip it on your own pets."
end
function P.CheckSoulboundOffer(t)
 -- A confirmation sent before upgrading may already have committed remotely.
 -- Preserve its exact-once delivery/cancellation protocol, never refund locally.
 if not t.soulboundRules and (t.ready or t.decision)then return true end
 local decode=t.protocol==2 and F.Trades.Decode or F.LegacyTrades.Decode
 local function check(wires)
  for _,wire in ipairs(wires or {})do
   local e=decode(wire);local why=e and P.SoulboundReason(e.kind,e.item)
   if why then return false,why.." Remove it from the offer or cancel this trade."end
  end
  return true
 end
 local ok,why=check(t.protocol==2 and t.ownWires or {t.wire})
 if not ok then return false,why end
 return check(t.protocol==2 and t.remoteWires or {t.remote})
end
local description=P.GearDescription
function P.GearDescription(item)
 local text=description(item);local why=P.SoulboundReason("gear",item)
 return text..(why and "\n|cffffd100"..why.."|r" or "")
end
local specialty=P.Specialty
function P.Specialty(pet)
 return specialty(pet)..(P.IsSoulbound("pet",pet) and "\n|cffffd100Soulbound|r" or "")
end

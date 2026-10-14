local _,F=...
local I=F.Housing.Island
-- Native M2 models only; never load WMO buildings into actors.
I.storeCategories={}
I.storeCategoryOrder={}
I.storeExtras={}
I.storeCategoryOrder[#I.storeCategoryOrder+1]="Furniture"
I.storeCategories["Furniture"]={"chair","armchair","table","sofa","bed","shelf","bunk","bench","dining","farmchair","shelves","darkbed"}
I.storeExtras[#I.storeExtras+1]={key="bunk",name="Bunk bed",width=3,asset={id=198001,path="World/Generic/Human/Passive Doodads/BEDS/Bunkbed01.m2"}}
I.storeExtras[#I.storeExtras+1]={key="bench",name="Park bench",width=3,asset={id=198015,path="World/Generic/Human/Passive Doodads/Benches/StormWindBench01.M2"}}
I.storeExtras[#I.storeExtras+1]={key="dining",name="Farm table",width=3,asset={id=190673,path="World/Azeroth/Westfall/PassiveDoodads/WestfallTable/WestfallTable.m2"}}
I.storeExtras[#I.storeExtras+1]={key="farmchair",name="Farm stool",width=1.4,asset={id=190658,path="World/Azeroth/Westfall/PassiveDoodads/WestfallChair/WestfallChair.m2"}}
I.storeExtras[#I.storeExtras+1]={key="shelves",name="Abbey shelves",width=3,asset={id=198049,path="World/Generic/Human/Passive Doodads/BookShelves/AbbeyShelf02.m2"}}
I.storeExtras[#I.storeExtras+1]={key="darkbed",name="Carved bed",width=3,asset={id=198002,path="World/Generic/Human/Passive Doodads/BEDS/DuskwoodBed.m2"}}
I.storeCategoryOrder[#I.storeCategoryOrder+1]="Decor"
I.storeCategories["Decor"]={"rug","plant","bowls","lamp","book","books","streetlamp","sign"}
I.storeExtras[#I.storeExtras+1]={key="book",name="Open book",width=0.7,asset={id=198019,path="World/Generic/Human/Passive Doodads/BOOKS/BookLargeOpen01.m2"}}
I.storeExtras[#I.storeExtras+1]={key="books",name="Stack of books",width=0.8,asset={id=198056,path="World/Generic/Human/Passive Doodads/BookStacks/GeneralBookStackTall01.M2"}}
I.storeExtras[#I.storeExtras+1]={key="streetlamp",name="Street lamp",width=1.3,asset={id=198316,path="World/Generic/Human/Passive Doodads/Lamps/StormwindStreetlamp01.m2"}}
I.storeExtras[#I.storeExtras+1]={key="sign",name="Stone pillar",width=1.5,asset={id=198463,path="World/Generic/Human/Passive Doodads/SignPosts/HumanSignPost01.m2"}}
I.storeCategoryOrder[#I.storeCategoryOrder+1]="Storage"
I.storeCategories["Storage"]={"barrel","crate","grain","opencrate","wagon","haywagon"}
I.storeExtras[#I.storeExtras+1]={key="barrel",name="Wooden barrel",width=1.4,asset={id=190535,path="World/Azeroth/Westfall/PassiveDoodads/BARREL/WestFallBarrel01.m2"}}
I.storeExtras[#I.storeExtras+1]={key="crate",name="Supply crate",width=1.6,asset={id=190543,path="World/Azeroth/Westfall/PassiveDoodads/Crate/WestFallCrate.m2"}}
I.storeExtras[#I.storeExtras+1]={key="grain",name="Grain crate",width=1.5,asset={id=198158,path="World/Generic/Human/Passive Doodads/CRATES/CrateGrain01.m2"}}
I.storeExtras[#I.storeExtras+1]={key="opencrate",name="Open crate",width=1.5,asset={id=198161,path="World/Generic/Human/Passive Doodads/CRATES/CrateGrainOpen.m2"}}
I.storeExtras[#I.storeExtras+1]={key="wagon",name="Farm wagon",width=4,asset={id=190657,path="World/Azeroth/Westfall/PassiveDoodads/Westfall Wagon/WestfallWagon01.M2"}}
I.storeExtras[#I.storeExtras+1]={key="haywagon",name="Hay wagon",width=4,asset={id=190599,path="World/Azeroth/Westfall/PassiveDoodads/HayWagon/WestfallHayWagon.m2"}}
I.storeCategoryOrder[#I.storeCategoryOrder+1]="Garden"
I.storeCategories["Garden"]={"palm","fir","pine2","pine","rock","bush","flowers","fence","post","hay"}
I.storeExtras[#I.storeExtras+1]={key="bush",name="Leafy bush",width=2,asset={id=189692,path="World/Azeroth/ELWYNN/PASSIVEDOODADS/Bush/ElwynnBush01.m2"}}
I.storeExtras[#I.storeExtras+1]={key="flowers",name="Wildflowers",width=1.5,asset={id=189742,path="World/Azeroth/ELWYNN/PASSIVEDOODADS/Detail/ElwynnDetailFlowers/ElwynnDetailFlowers01.m2"}}
I.storeExtras[#I.storeExtras+1]={key="fence",name="Fence section",width=3,asset={id=190659,path="World/Azeroth/Westfall/PassiveDoodads/WestfallFence/WestfallFence.m2"}}
I.storeExtras[#I.storeExtras+1]={key="post",name="Fence post",width=0.5,asset={id=190661,path="World/Azeroth/Westfall/PassiveDoodads/WestfallFence/WestfallFencepost.m2"}}
I.storeExtras[#I.storeExtras+1]={key="hay",name="Haystack",width=2.5,asset={id=190597,path="World/Azeroth/Westfall/PassiveDoodads/HayStack/WestFallHayStack01.m2"}}
I.storeCategoryOrder[#I.storeCategoryOrder+1]="Buildings"
I.storeCategories["Buildings"]={"shed","farmhouse","stagehouse","hut","stable"}
I.storeExtras[#I.storeExtras+1]={key="shed",name="Westfall shed",width=6,asset={id=190517,path="World/Azeroth/Westfall/BUILDINGS/Shed/WestfallShed.m2"}}
I.storeExtras[#I.storeExtras+1]={key="farmhouse",name="Small farmhouse",width=8,asset={id=203656,path="World/Lordaeron/ARATHI/PASSIVEDOODADS/FarmHouses/ArathiFarmHouse01.M2"}}
I.storeExtras[#I.storeExtras+1]={key="stagehouse",name="Cottage facade",width=7,asset={id=190060,path="World/Azeroth/Karazahn/PassiveDoodads/Theater/Karazahn_RRH_House.m2"}}
I.storeExtras[#I.storeExtras+1]={key="hut",name="Swamp hut",width=6,asset={id=190430,path="World/Azeroth/SwampOSorrow/PassiveDoodads/WaterHuts/WaterHut01.m2"}}
I.storeExtras[#I.storeExtras+1]={key="stable",name="Farm stable",width=7,asset={id=190655,path="World/Azeroth/Westfall/PassiveDoodads/Westfall Stable/WestFallStable01.m2"}}

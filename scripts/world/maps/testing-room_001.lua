return {
 version="1.10",luaversion="5.1",tiledversion="1.10.2",class="",orientation="orthogonal",renderorder="right-down",
 width=16,height=12,tilewidth=40,tileheight=40,infinite=false,backgroundcolor={23,27,43,255},
 nextlayerid=5,nextobjectid=11,properties={name="testing-room_001"},tilesets={},
 layers={
 {type="tilelayer",id=1,name="floor",class="",encoding="lua",width=16,height=12,x=0,y=0,opacity=1,visible=true,offsetx=0,offsety=0,parallaxx=1,parallaxy=1,properties={},data={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}},
 {type="objectgroup",id=2,name="collision",class="collision",draworder="topdown",visible=true,opacity=1,offsetx=0,offsety=0,parallaxx=1,parallaxy=1,properties={},objects={
 {id=1,name="north_wall",x=0,y=0,width=640,height=40,rotation=0,visible=true,properties={}},
 {id=2,name="south_wall",x=0,y=440,width=640,height=40,rotation=0,visible=true,properties={}},
 {id=3,name="west_wall",x=0,y=0,width=40,height=480,rotation=0,visible=true,properties={}},
 {id=4,name="east_wall",x=600,y=0,width=40,height=480,rotation=0,visible=true,properties={}}}},
 {type="objectgroup",id=3,name="markers",class="markers",draworder="topdown",visible=true,opacity=1,offsetx=0,offsety=0,parallaxx=1,parallaxy=1,properties={},objects={
 {id=5,name="spawn",shape="point",x=320,y=350,width=0,height=0,rotation=0,visible=true,properties={}}}},
 {type="objectgroup",id=4,name="objects",class="objects",draworder="topdown",visible=true,opacity=1,offsetx=0,offsety=0,parallaxx=1,parallaxy=1,properties={},objects={
 {id=6,name="interactable",shape="rectangle",x=85,y=190,width=110,height=64,rotation=0,visible=true,properties={script="gaster_fight_test"}},
 {id=7,name="interactable",shape="rectangle",x=265,y=190,width=110,height=64,rotation=0,visible=true,properties={script="final_fight_test"}},
 {id=8,name="interactable",shape="rectangle",x=445,y=190,width=110,height=64,rotation=0,visible=true,properties={script="runtime_test"}},
 {id=9,name="savepoint",shape="rectangle",x=300,y=285,width=40,height=40,rotation=0,visible=true,properties={marker="spawn",heals=true,text1_1="* Welcome to testing-room_001.",text1_2="* Choose a test station to begin."}},
 {id=10,name="interactable",shape="rectangle",x=300,y=95,width=40,height=54,rotation=0,visible=true,properties={script="gaster_dialogue_test",label="Gaster Statue"}}}}
 }
}
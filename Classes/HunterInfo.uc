class HunterInfo extends actor;

var DeusExPlayer P;
var string OwnerName;

var bool Hunting;
var bool PrimeHunter;
var HuntersMut WorldMutator;
var DeusExPlayer FoundBy;
var Beam HuntLight;

function Tick(float deltatime){
    local vector pos;
    if(P != None && OwnerName != P.PlayerReplicationInfo.PlayerName) 
        OwnerName = P.PlayerReplicationInfo.PlayerName;
        
    if(P == None || P.isInState('Spectating')){
        HuntLight.Destroy();
        Destroy();
        BroadcastMessage("|P2"$OwnerName$" has evaded the hunt.");
        return;
    }
    

    
    if(HuntLight != None){
        pos = P.Location + vect(0,0,1)*P.BaseEyeHeight + vect(1,1,0)*vector(P.Rotation)*P.CollisionRadius*1.5;
        HuntLight.SetLocation(pos);
    }
}

function AddLight(){
    if(HuntLight == None) HuntLight = Spawn(class'Beam', p, '', p.Location);;
    
    HuntLight.LightType = WorldMutator.HunterLightType;
    HuntLight.LightEffect = WorldMutator.HunterLightEffect;
    HuntLight.LightHue = WorldMutator.HunterLightHue;
    HuntLight.LightRadius = WorldMutator.HunterLightRadius;
    HuntLight.LightSaturation = WorldMutator.HunterLightSaturation;
    HuntLight.LightBrightness = WorldMutator.HunterLightBrightness;
}

function DeleteLight(){
    HuntLight.LightType = LT_None;
    HuntLight.LightRadius = 0;
    if(HuntLight != None) HuntLight.Destroy();
    HuntLight = None;
}

defaultproperties
{
    bHidden=True
    OwnerName="A player"
}

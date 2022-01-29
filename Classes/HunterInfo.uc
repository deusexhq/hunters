class HunterInfo extends actor;

var DeusExPlayer P;
var string OwnerName;

var bool Hunting;
var bool PrimeHunter;
var HuntersMut WorldMutator;
var DeusExPlayer FoundBy, testPlayer;
var Beam HuntLight;
var int DeadSecs;

function DeusExPlayer getPlayer(){
    local DeusExPlayer dxp;
    foreach AllActors(class'DeusExPlayer', dxp){ if(dxp.PlayerReplicationInfo.PlayerName == ownerName) return dxp;}
}

function Timer(){
	local DeusExPlayer fp;

    if(P.IsInState('Dying') || P.Health <= 0){
        DeadSecs++;
    } else DeadSecs = 0;
    
    if(DeadSecs >= 10){
        BroadcastMessage("|P2"$OwnerName$" has died of old age and has been removed from the game.");
        HuntLight.Destroy();
        Destroy();
    }

	testPlayer = getPlayer();

	if (WorldMutator.isOpenDX() && testPlayer != None && !Hunting) {
        testPlayer.SetPropertyText("TeamName", "Hiding");
        testPlayer.PlayerReplicationInfo.SetPropertyText("TeamNamePRI", "Hiding");
	}

	if(testPlayer != None && Hunting == False){
		foreach testPlayer.radiusActors(class'DeusExPlayer', fp, WorldMutator.evasionRange){
			if (fp.physics == PHYS_None){
				fp.setPhysics(PHYS_Falling);
				fp.clientMessage("|P3The hunter is nearby... Run, if you dare.");
			}
		}
	}
}

function Tick(float deltatime){
    local vector pos;
	
    if(P == None || testPlayer == None || P.isInState('Spectating')){
        BroadcastMessage("|P2"$OwnerName$" has evaded the hunt.");
        HuntLight.Destroy();
        Destroy();
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

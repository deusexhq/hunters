//=============================================================================
// WeaponStealthPistol.
//=============================================================================
class WeaponHunter extends DeusExWeapon;

var HuntersMut WorldMutator;

state Idle
{
	function BeginState()
	{
		local HunterInfo inf;
		Super.BeginState();
		inf = WorldMutator.GetHunterPlayerInfo(DeusExPlayer(Owner));

		if (WorldMutator.isOpenDX() && inf != None && inf.Hunting && DeusExPlayer(Owner) != None){
			DeusExPlayer(Owner).SetPropertyText("TeamName", "Hunters");
		    DeusExPlayer(Owner).PlayerReplicationInfo.SetPropertyText("TeamNamePRI", "Hunters");
		}
	}
}

simulated function PreBeginPlay()
{
    Super.PreBeginPlay();

    // If this is a netgame, then override defaults
    if ( Level.NetMode != NM_StandAlone )
    {
        HitDamage = mpHitDamage;
        BaseAccuracy = mpBaseAccuracy;
        ReloadTime = mpReloadTime;
        AccurateRange = mpAccurateRange;
        MaxRange = mpMaxRange;
        ReloadCount = mpReloadCount;
    }
}

function string GetName(DeusExPlayer P){ return p.PlayerReplicationInfo.PlayerName; }

simulated function bool TestMPBeltSpot(int BeltSpot){ return ( (BeltSpot >= 1) && (BeltSpot <=9) ); }

Function LaserToggle(){
    //Show hunters
    local HunterInfo h;
    local int hunters, hiders, total;
    
    DeusExPlayer(Owner).ClientMessage("|P7Game Statistics:");
    foreach AllActors(class'HunterInfo', h){ 
        if(h.Hunting) {
            DeusExPlayer(Owner).ClientMessage("|P2HUNTER: "$GetName(h.p)); 
            hunters++;
        } else {
            DeusExPlayer(Owner).ClientMessage("|P4HIDER: "$GetName(h.p)); 
            hiders++;
        }
        
        total++;
    }
    BroadcastMessage(hunters@"players are hunting,"@hiders@"are hiding, out of"@total@"total players.");
}

function ScopeToggle(){
    local HunterInfo inf;
    inf = WorldMutator.GetHunterPlayerInfo(DeusExPlayer(Owner));
    if(inf.FoundBy != None){
        DeusExPlayer(Owner).ClientMessage("You were caught be "$inf.FoundBy.PlayerReplicationInfo.PlayerName);
    } else {
        DeusExPlayer(Owner).ClientMessage("You were not caught by anyone.");
    }
}

function ProcessTraceHit(Actor Other, Vector HitLocation, Vector HitNormal, Vector X, Vector Y, Vector Z){
    local HuntersMut hm;
    local HunterInfo inf;
    local DeusExPlayer me, them, allPlayers;
    local bool bGood;
    
    bGood = False;
    
    me = DeusExPlayer(Owner);
    
    if(WorldMutator == None){ foreach AllActors(class'HuntersMut', hm) WorldMutator = hm; }
    if(WorldMutator == None) Destroy();
    
    if(Other.isa('DeusExPlayer') && WorldMutator.hasHunterPlayerInfo(DeusExPlayer(Other))){
        them = DeusExPlayer(Other);
        inf = WorldMutator.GetHunterPlayerInfo(them);
        if(inf.Hunting){
            Me.ClientMessage("|p2"$Them.PlayerReplicationInfo.PlayerName$" is a hunter!");
        } else {
            inf.FoundBy = me;
            inf.Hunting = True;
            BroadcastMessage("|P7"$them.PlayerReplicationInfo.PlayerName$" was caught by "$me.PlayerReplicationInfo.PlayerName);
            WorldMutator.GiveHunterWeapon(them);
            WorldMutator.LightUp(them);
            them.SetPhysics(PHYS_Falling);
            bGood = True;
            if(WorldMutator.bPlaySounds) me.ClientPlaySound(WorldMutator.HunterCatchSnd);
            if(WorldMutator.bPlaySounds) them.ClientPlaySound(WorldMutator.PlayerCaughtSnd);
            if(WorldMutator.IsOpenDX()){
                them.SetPropertyText("TeamName", "Hunters");
                them.PlayerReplicationInfo.SetPropertyText("TeamNamePRI", "Hunters");
            }
            
            if(WorldMutator.ScorePerCatch != 0){
                //Handle scoring
                them.PlayerReplicationInfo.deaths += 1;
                them.PlayerReplicationInfo.streak = 0;
                me.PlayerReplicationInfo.Score += WorldMutator.ScorePerCatch;
            }
            
            if(WorldMutator.bHuntCamera){
                foreach AllActors(class'DeusExPlayer', allPlayers){
                    if(allPlayers != me && allPlayers != them && !allPlayers.isinState('Spectating') ){
                        allPlayers.ClientMessage("|P7Camera will switch to "$them.PlayerReplicationInfo.PlayerName$"\'s location shortly...");
                    }
                }
                
                WorldMutator.TimeToHookCams = WorldMutator.Loops + 3;
                WorldMutator.bHookingCams = True;
                WorldMutator.LastCaughtPlayer = them;
                WorldMutator.LastCatchPlayer = me;
            }
        }
    }
    
    if(!WorldMutator.hasHunterPlayerInfo(DeusExPlayer(Other))){
        me.ClientMessage("That target is not a player.");
    }
        
    if(!bGood && WorldMutator.bHardMode){
        if(WorldMutator.bPlaySounds) me.ClientPlaySound(WorldMutator.HunterErrorSnd);
        DeusExPlayer(Owner).ClientMessage("|P2That was a bad guess!");
        DeusExPlayer(Owner).TakeDamage(WorldMutator.HardModeDamage, DeusExPlayer(Owner), Owner.Location, vect(0,0,1),'Shot');
    }
}

simulated function float CalculateAccuracy() { return 0.000000; }

state NormalFire //(Thanks to JimBowen for this Infinite ammo code) 
{ 
Begin: 
    if ((ClipCount >= ReloadCount) && (ReloadCount != 0)) 
    { 
        if (!bAutomatic) 
        { 
            bFiring = False; 
            FinishAnim(); 
        } 
    
        if (Owner != None) 
        { 
            if (Owner.IsA('DeusExPlayer')) 
            { 
            bFiring = False; 
            } 
            else if (Owner.IsA('ScriptedPawn')) 
            { 
            bFiring = False; 
            ReloadAmmo(); 
            } 
        } 
        else 
        { 
            if (bHasMuzzleFlash) 
            EraseMuzzleFlashTexture(); 
            GotoState('Idle'); 
        } 
    } 
    if ( bAutomatic && (( Level.NetMode == NM_DedicatedServer ) || ((Level.NetMode == NM_ListenServer) && Owner.IsA('DeusExPlayer') && !DeusExPlayer(Owner).PlayerIsListenClient()))) 
        GotoState('Idle'); 
    
    Sleep(GetShotTime()); 
    if (bAutomatic) 
    { 
        GenerateBullet();       // In multiplayer bullets are generated by the client which will let the server know when 
        Goto('Begin'); 
    } 
    bFiring = False; 
    FinishAnim(); 
    
/*      // if ReloadCount is 0 and we're not hand to hand, then this is a 
    // single-use weapon so destroy it after firing once 
    if ((ReloadCount == 0) && !bHandToHand) 
    { 
        if (DeusExPlayer(Owner) != None) 
            DeusExPlayer(Owner).RemoveItemFromSlot(Self);   // remove it from the inventory grid 
        Destroy(); 
    } 
    */              // Do I REALLY need all that crap JUST for infinite ammo? 
    ReadyToFire(); 
Done: 
    bFiring = False; 
    Finish(); 
}


defaultproperties
{
    GoverningSkill=Class'DeusEx.SkillWeaponPistol'
    NoiseLevel=0.010000
    ShotTime=0.150000
    reloadTime=1.500000
    HitDamage=0
    maxRange=4800
    AccurateRange=2400
    BaseAccuracy=0.800000
    bCanHaveScope=True
    ScopeFOV=25
    bCanHaveLaser=True
    recoilStrength=0.100000
    mpBaseAccuracy=0.200000
    mpAccurateRange=1200
    mpMaxRange=1200
    bCanHaveModBaseAccuracy=True
    bCanHaveModReloadCount=True
    bCanHaveModAccurateRange=True
    bCanHaveModReloadTime=True
    bInstantHit=True
    FireOffset=(X=-24.000000,Y=10.000000,Z=14.000000)
    shakemag=50.000000
    FireSound=Sound'DeusExSounds.Weapons.StealthPistolFire'
    AltFireSound=Sound'DeusExSounds.Weapons.StealthPistolReloadEnd'
    CockingSound=Sound'DeusExSounds.Weapons.StealthPistolReload'
    SelectSound=Sound'DeusExSounds.Weapons.StealthPistolSelect'
    InventoryGroup=128
    ItemName="Hunter Gun"
    PlayerViewOffset=(X=24.000000,Y=-10.000000,Z=-14.000000)
    PlayerViewMesh=LodMesh'DeusExItems.StealthPistol'
    PickupViewMesh=LodMesh'DeusExItems.StealthPistolPickup'
    ThirdPersonMesh=LodMesh'DeusExItems.StealthPistol3rd'
    Icon=Texture'DeusExUI.Icons.BeltIconStealthPistol'
    largeIcon=Texture'DeusExUI.Icons.LargeIconStealthPistol'
    largeIconWidth=47
    largeIconHeight=37
    Description="The stealth pistol is a variant of the standard 10mm pistol with a larger clip and integrated silencer designed for wet work at very close ranges."
    beltDescription="Hunter"
    Mesh=LodMesh'DeusExItems.StealthPistolPickup'
    CollisionRadius=8.000000
    CollisionHeight=0.800000
}

//=============================================================================
// Hunters
//=============================================================================
class HuntersMut extends Mutator Config (Hunters);

var HunterInfo PrimeHunter;
var int HideRound;
var bool bHSOn;
var bool bHidePhase; 
var int Loops;

var() config bool bHideWeapons;
var() config bool bUnlockDoors;
var() config bool bGodMode;
var() config  bool bHardMode;

var() config  int HideLength;

function ModifyPlayer(Pawn Other)
{
    local DeusExPlayer P;

    P = DeusExPlayer(Other);

    //if(P==PrimeHunter) GiveHunterWeapon(P);
    if(hasHunterPlayerInfo(P) && GetHunterPlayerInfo(P).Hunting) GiveHunterWeapon(P);
    Super.ModifyPlayer(Other);
}

function BeginHunter(DeusExPlayer Seeker){
    // iterate all players
    // If OpenDX is found, set players teams
    // God everyone -- scratch that, use a takedamage mutator hook to disable damage against players while HS is on
    local DeusExPlayer DXP;
    local HunterInfo h;
    local DeusExWeapon W;
    local DeusExMover mv;
    local Teleporter tp;
    local DatalinkTrigger dl;
    local ComputerSecurity sc;
    local SecurityCamera cam;
    local AutoTurret at;
    local AutoTurretGun atg;
    
    
    PrimeHunter = CreatePlayerHunterInfo(Seeker);
    PrimeHunter.Hunting = True;
    Seeker.bHidden=False;
    HideRound++;
    BroadcastMessage("|P2Hunters game has begun. [Round "$HideRound$"]");
    BroadcastMessage(Seeker.PlayerReplicationInfo.PlayerName$" is now a Hunter.");
    if(IsOpenDX()) PrimeHunter.P.ConsoleCommand("CreateTeam2 Hunters");
    //BroadcastMessage("HIDE PHASE: Players are invisible, seeker is locked in position.");
    bHidePhase=True;
    SetTimer(HideLength,False);
    
    foreach allactors(class'Teleporter',tp) {
        ConsoleCommand("set teleporter bstatic 0");
        tp.bHidden = False;
        tp.Destroy();
    }
    
    foreach allactors(class'AutoTurret',at) {
        at.Untrigger(Seeker, Seeker);
        at.bDisabled = True;
        at.bActive = False;
    }
      
    foreach allactors(class'AutoTurretGun',atg) {
        atg.bHidden = True;
    }
    
    foreach allactors(class'SecurityCamera',cam) {
        cam.Untrigger(Seeker, Seeker);
        cam.bActive = False;
    }
    
    foreach allactors(class'ComputerSecurity',sc) {
        sc.bHidden = True;
    }
    
    foreach allactors(class'DatalinkTrigger',dl) {
        ConsoleCommand("set DatalinkTrigger bstatic 0");
        dl.bHidden = False;
        dl.Destroy();
    }
        
    if(bHideWeapons){
        foreach allactors(class'DeusExWeapon',W) {
            W.bHidden = True;
        }
    }
    
    if(bUnlockDoors){
        foreach allactors(class'DeusExMover', mv) {
            mv.bLocked = False;
        }
    }

    
    foreach allactors(class'DeusExPlayer',DXP) {
        if(IsOpenDX()){
            DXP.SetPropertyText("HUD_Type", "HUD_Off");
            
        }
        if(!DXP.isinState('Spectating') && DXP != Seeker) {
            DXP.ClientMessage("You are a hider, hide somewhere that Hunter "$GetName(Seeker)$" may not find you!");
            h = CreatePlayerHunterInfo(DXP);
            h.Hunting = False;
            DXP.bHidden=True;
            if(IsOpenDX()){
                DXP.SetPropertyText("TeamName", "Hiding");
                DXP.PlayerReplicationInfo.SetPropertyText("TeamNamePRI", "Hiding");
            }
        }
    }
    bHSOn = True;
}

function CleanupHunter(){
    //Degod everyone
    //Remove players OpenDX teams
    local WeaponHunter PGS;
    local HunterInfo inf;
    local DeusExPlayer DXP;
    local DeusExWeapon w;
    bHSOn = False;
    foreach allactors(class'WeaponHunter',PGS) PGS.Destroy();
    foreach allactors(class'HunterInfo',inf) PGS.Destroy();
    foreach allactors(class'DeusExWeapon',W) {
        W.bHidden = False;
    }
    
    foreach allactors(class'DeusExPlayer',DXP) {
        if(IsOpenDX()){
            DXP.SetPropertyText("HUD_Type", "HUD_Extended");
            DXP.SetPropertyText("TeamName", "");
            DXP.PlayerReplicationInfo.SetPropertyText("TeamNamePRI", "");
        }
    }
        
}

function PostBeginPlay ()
{
    Level.Game.BaseMutator.AddMutator (Self);
    bHSOn=False;
    HideRound = 0;
    //super.PostBeginPlay();
}

function bool IsOpenDX(){
    local class<actor> testclass;
    local bool good;
    
    testclass = class<actor>( DynamicLoadObject( "OpenDX.TCPlayer", class'Class' ) );
    Log(testclass);
    if(testclass != None)
        return true;
    else
        return false;
}
function Timer()
{
    local DeusExPlayer dxp;
    local HunterInfo h;
    local int hunters, hiders, total;
    if(!bHSOn) return;
    
    if(bHidePhase){
        BroadcastMessage("|P2The hunt is on.");
        bHidePhase=False;
        GiveHunterWeapon(PrimeHunter.P);
        foreach allactors(class'DeusExPlayer',DXP)
        {
            if(!DXP.isinState('Spectating'))
            {
                DXP.bHidden=False;
            }
        }
        SetTimer(10, False);
    } else {
        foreach AllActors(class'HunterInfo', h){ 
            if(h.Hunting) { hunters++;
            } else {
                if(Loops % 30 == 0) BroadcastMessage("|P4Still hiding: "$GetName(h.p)); 
                hiders++;
            }
            total++;
        }
        
        if(hunters == 0){
            BroadcastMessage("|P2No hunters left. Game over.");
            CleanupHunter();
        }
        if(hiders == 0){
            BroadcastMessage("|P2Everyone has been found! Game over.");
            CleanupHunter();
        }
        Loops++;
        SetTimer(1, False);
    }
}

function Mutate (String S, PlayerPawn PP)
{
    local int ID, JSlot;
    local string part, pg;
    local Pawn APawn;
    local DeusExPlayer DXP;

    Super.Mutate (S, PP);
    
        if(S ~= "GameCommands")
        {
        }
        
        if(S ~= "Games")
        {
            
            if(bHSOn) //TODO update this for handling through HunterInfos
            {
                BroadcastMessage("Hide and Seek is active! [Round "$HideRound$"]");
                BroadcastMessage("Seeker: "$PrimeHunter.P.PlayerReplicationInfo.PlayerName);

            }
        }
    
        
        if(S ~= "hunter.start" && !bHSOn  ) 
        {
            bHSOn=True;

            BeginHunter(DeusExPlayer(PP));

        }
        
        if(S ~= "hunter.start.random" && !bHSOn  ) 
        {
            bHSOn=True;
            //TODO select random user

            BeginHunter(DeusExPlayer(PP));

        }
        
        if(S ~= "HideEnd" && bHSOn && DeusExPlayer(PP).bAdmin)
        {
            CleanupHunter();
        }
        
        if( DeusExPlayer(PP).bAdmin && S ~= "ClearScore"  && !bHSOn )
        {
            BroadcastMessage("Scoreboard reset.");
            ResetScores();
        }
}







function ResetScores()
{
    local PlayerReplicationInfo PRI;
    foreach allactors(class'PlayerReplicationInfo',PRI)
    {
        PRI.Score = 0;
        PRI.Deaths = 0;
        PRI.Streak = 0;
    }
}

function string GetName(DeusExPlayer P){ return p.PlayerReplicationInfo.PlayerName; }

function DeusExPlayer getPlayer(int id){
    local DeusExPlayer dxp;
    foreach AllActors(class'DeusExPlayer', dxp){ if(dxp.PlayerReplicationInfo.PlayerID == id) return dxp;}
}

function HunterInfo GetInfo(int id){
    local HunterInfo h;
    foreach AllActors(class'HunterInfo', h){ if(h.P.PlayerReplicationInfo.PlayerID == id) return h; }
}
function HunterInfo GetHunterPlayerInfo(DeusExPlayer DXP){
    local HunterInfo h;
    foreach AllActors(class'HunterInfo', h){ if(h.P == dxp) return h; }
}
function bool hasHunterInfo(int id){
    local HunterInfo h;
    foreach AllActors(class'HunterInfo', h){ if(h.P.PlayerReplicationInfo.PlayerID == id) return true; }
    return false;
}
function bool hasHunterPlayerInfo(DeusExPlayer DXP){
    local HunterInfo h;
    foreach AllActors(class'HunterInfo', h){ if(h.P == DXP) return true; }
    return false;
}
function HunterInfo CreateHunterInfo(int id){
    local HunterInfo h;
    local DeusExPlayer dxp;
    h = Spawn(class'HunterInfo');
    h.P = getPlayer(id);
    h.WorldMutator = self;
    return h;
}

function HunterInfo CreatePlayerHunterInfo(DeusExPlayer p){
    local HunterInfo h;
    h = Spawn(class'HunterInfo');
    h.P = p;
    h.WorldMutator = self;
    return h;
}
function GiveHunterWeaponID(int id){
    local DeusExPlayer dxp;
    foreach AllActors(class'DeusExPlayer', dxp){ if(dxp.PlayerReplicationInfo.PlayerID == id) GiveHunterWeapon(dxp); }
}

function GiveHunterWeapon(DeusExPlayer p){
    local inventory inv;
    inv=Spawn(class'WeaponHunter');
    Inv.Frob(p,None);
    Inventory.bInObjectBelt = True;
    inv.Destroy();
}

defaultproperties
{
    bHideWeapons=True
    bUnlockDoors=True
    HideLength=60
}

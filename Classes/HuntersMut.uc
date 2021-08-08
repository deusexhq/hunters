//=============================================================================
// Hunters
//=============================================================================
class HuntersMut extends Mutator Config (Hunters);

#exec AUDIO IMPORT FILE="Sounds\begin.wav" NAME="h_begin" GROUP="Generic"
#exec AUDIO IMPORT FILE="Sounds\huntison.wav" NAME="h_huntison" GROUP="Generic"
#exec AUDIO IMPORT FILE="Sounds\confirmed.wav" NAME="h_confirmed" GROUP="Generic"
#exec AUDIO IMPORT FILE="Sounds\caught.wav" NAME="h_caught" GROUP="Generic"
#exec AUDIO IMPORT FILE="Sounds\errored.wav" NAME="h_errored" GROUP="Generic"
#exec AUDIO IMPORT FILE="Sounds\alert.wav" NAME="h_alert" GROUP="Generic"
#exec AUDIO IMPORT FILE="Sounds\gameover.wav" NAME="h_gameover" GROUP="Generic"
var HunterInfo PrimeHunter; //The MC of each round
var int HideRound; //How many rounds have we done
var bool bHSOn; //Are we active
var bool bHidePhase; //Phase where players can hide from the hunter
var int Loops; //How many times has the round timer looped, can be used to measure how long the round has gone on for
var bool bEndless; //Does a new round begin right after the last one ended automatically?
var bool bWaitingNewRound; //Are we currently between two endless rounds?
var bool bFinalRound; //Have we designated that Endless will end after this round?

var() config bool bDebug;
var() config bool bHideWeapons; //Hides weapons in the map when game is active
var() config bool bUnlockDoors; //Unlocks all doors in the map
var() config bool bGodMode; //No damage for players while game is active
var() config bool bHardMode; //Limited number of attempts by the hunters
var() config bool bTimeLimit;
var() config int TimeLimit;
var() config int HardModeDamage;
var() config int TimeBetweenRounds; //How long do we wait between endless rounds before starting a new one
var() config int TimeToHide; //How long do players have to hide before the hunter is let loose.
var() config int OutputMod; //Used to check wether player info should be displayed
var() config int TimeLimitReminder; //Seperate delay for when time remaining should be shown in speedrun mode
var() config bool bLighting; //Highlight hunters with a light effect?
var() config bool bPlaySounds; //Use sound effects?

var() config ELightType HunterLightType;
var() config ELightEffect HunterLightEffect;
var() config byte HunterLightRadius;
var() config byte HunterLightBrightness;
var() config byte HunterLightSaturation;
var() config byte HunterLightHue;

var() config sound HuntBeginSnd; //begin
var() config sound HuntRoundStartSnd; //huntison
var() config sound HunterCatchSnd; //confirmed
var() config sound PlayerCaughtSnd; //caught
var() config sound HunterErrorSnd; //errored
var() config sound GameOverSnd; //gameover

function ModifyPlayer(Pawn Other){
    local DeusExPlayer P;
    P = DeusExPlayer(Other);

    // Give players on the hunter team the weapon when they respawn
    if(hasHunterPlayerInfo(P) && GetHunterPlayerInfo(P).Hunting) GiveHunterWeapon(P);
    Super.ModifyPlayer(Other);
}

function BeginHunter(DeusExPlayer Seeker){
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
    local MissionScript ms;

    //Defining our main character of the round
    PrimeHunter = CreatePlayerHunterInfo(Seeker);
    if(bLighting) LightUp(Seeker);
    PrimeHunter.Hunting = True;
    Seeker.bHidden=False;
    HideRound++;
    bWaitingNewRound = False;
    BroadcastMessage("[Hunt] |P2Hunters game has begun. [Round "$HideRound$"]");
    BroadcastMessage("[Hunt] "$Seeker.PlayerReplicationInfo.PlayerName$" is now a Hunter.");
    if(IsOpenDX()) PrimeHunter.P.ConsoleCommand("CreateTeam2 Hunters"); //If OpenDX is installed, set the hunter to a team to show in the scoreboard

    //Giving players the hide phase
    bHidePhase=True;
    SetTimer(TimeToHide,False);
    
    PlayToEveryone(HuntBeginSnd);
    
    //Map cleanup actions
    foreach allactors(class'MissionScript',ms) {
        ConsoleCommand("set MissionScript bstatic 0");
        ms.bHidden = False;
        ms.Destroy();
    }
    
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
            if(W.Owner != None) w.Destroy();
        }
    }
    
    if(bUnlockDoors){
        //foreach allactors(class'DeusExMover', mv) {
            //mv.bLocked = False;
        //}
    }

    
    foreach allactors(class'DeusExPlayer',DXP) {
        //If OpenDX is installed, turn off the IFF
        if(IsOpenDX()){
            DXP.SetPropertyText("HUDType", "HUD_Off");
            
        }
        
        if(!DXP.isinState('Spectating') && DXP != Seeker) {
            DXP.ClientMessage("You are hiding, hide somewhere that Hunter "$GetName(Seeker)$" may not find you!");
            //Create the info for the player to store their data
            h = CreatePlayerHunterInfo(DXP);
            h.Hunting = False;
            DXP.bHidden=True;
            
            // If OpenDX is installed, set their ODXDM Team Name
            if(IsOpenDX()){
                DXP.SetPropertyText("TeamName", "Hiding");
                DXP.PlayerReplicationInfo.SetPropertyText("TeamNamePRI", "Hiding");
            }
        }
    }
    bHSOn = True;
}

function CleanupHunter(){
    local WeaponHunter PGS;
    local HunterInfo inf;
    local DeusExPlayer DXP;
    local DeusExWeapon w;
    
    // Loop time
    // Hooking the game end function to redirect to starting a new round if we're in endless mode
    if(bEndless && !bFinalRound){
        SetTimer(TimeBetweenRounds, false);
        bWaitingNewRound = True;
        BroadcastMessage("|P7[Hunt] A new round will begin soon...");
    } 
    
    // Wether or not we're in endless mode, let's cleanup the last round
    bHSOn = False;
    Loops = 0;

    foreach allactors(class'DeusExPlayer',DXP) {
        if(IsOpenDX()){
            DXP.SetPropertyText("HUDType", "HUD_Extended");
            DXP.SetPropertyText("TeamName", "");
            DXP.PlayerReplicationInfo.SetPropertyText("TeamNamePRI", "");
        }
        if(bLighting) LightOff(dxp);
    }
    
    foreach allactors(class'WeaponHunter',PGS) PGS.Destroy();
    foreach allactors(class'HunterInfo',inf) inf.Destroy();
    foreach allactors(class'DeusExWeapon',W) W.bHidden = False;
    
}

function PostBeginPlay (){
    Level.Game.BaseMutator.AddMutator (Self);
    bHSOn=False;
    HideRound = 0;
    Loops = 0;
    //super.PostBeginPlay();
}

// OpenDX check
// Allows for checking if the mod is running, without requiring it as a dependency, so THIS mod can integrate with it, but also work without it
function bool IsOpenDX(){
    local class<actor> testclass;
    local bool good;
    
    // Try to load an OpenDX player class
    testclass = class<actor>( DynamicLoadObject( "OpenDX.TCPlayer", class'Class' ) );

    // If testclass is not None, it means TCPlayer exists on the server, so we can infer that OpenDX is running
    if(testclass != None)
        return true;
    else
        return false;
}

function Timer(){
    local DeusExPlayer dxp;
    local HunterInfo h;
    local int hunters, hiders, total;
    local int timeRemaining;
    
    // Do nothing if game is not running
    if(!bHSOn && !bWaitingNewRound) return;
    
    // If we're in endless and waiting for a new round, start the next round
    if(bWaitingNewRound){
        BroadcastMessage("|P2[Hunt] A new round begins!");
        BeginHunter(GetRandomPlayer());
    } else if(bHidePhase){
        PlayToEveryone(HuntRoundStartSnd);
        // If we're in hide phase, switch to main phase
        BroadcastMessage("|P2[Hunt] The hunt is on.");
        bHidePhase=False;
        GiveHunterWeapon(PrimeHunter.P);
        foreach allactors(class'DeusExPlayer',DXP) {
            if(!DXP.isinState('Spectating')) {
                DXP.bHidden=False;
            }
        }
        //Start the timer loop for displaying player info
        SetTimer(1, False);
    } else {
        //We're in a game, so let's show some info
        
        //Count each team's player count
        foreach AllActors(class'HunterInfo', h){ 
            if(h.Hunting) { 
                hunters++;
            } else {
                //Every OutputMod seconds, show the list
                if(Loops % OutputMod == 0) BroadcastMessage("|P4Still hiding: "$GetName(h.p)); 
                hiders++;
            }
            total++;
        }
        
        //Handling what we've counted
        
        //If there are no hunters (They left, maybe?) end the game as it is now unwinnable.
        if(hunters == 0){
            BroadcastMessage("|P2[Hunt] No hunters left. Game over.");
            PlayToEveryone(GameOverSnd);
            CleanupHunter();
        }
        
        //If all hiders have been fond, end the game.
        if(hiders == 0){
            BroadcastMessage("|P2[Hunt] Everyone has been found! Game over.");
            PlayToEveryone(GameOverSnd);
            CleanupHunter();
        }
        
        // IF the game didn't end from the previous checks, schedule the next loop
        if(bHSOn){
            Loops++;
            timeRemaining = TimeLimit - Loops;
            if(bTimeLimit && Loops % TimeLimitReminder == 0) BroadcastMessage("|P2"$timeRemaining$" seconds remaining for this hunt.");
            if(bTimeLimit && Loops > TimeLimit) {
                BroadcastMessage("|P2[Hunt] Hunter failed to find everyone. Game over.");
                CleanupHunter();
                PlayToEveryone(GameOverSnd);
            } else SetTimer(1, False);
        }

    }
}

function Mutate (String S, PlayerPawn PP){
    local HunterInfo h;
    local int hunters, hiders, total, timeRemaining;
    local string marg, mkey, mval;
    
    //Keep the mutator chain linked
    Super.Mutate (S, PP);
    
    
    if(S ~= "hunt.help") {
        PP.ClientMessage("Commands: hunt, hunt.start, hunt.random, hunt.endless, hunt.end, hunt.set <config key> <config value>, hunt.reset");
    }
    
    if(S ~= "hunt") {
        if(bHSOn) {
            BroadcastMessage("|P7Game is active! [Round "$HideRound$"]");
            BroadcastMessage("Prime Hunter: "$PrimeHunter.P.PlayerReplicationInfo.PlayerName);

            foreach AllActors(class'HunterInfo', h){ 
                if(h.Hunting) {
                    BroadcastMessage("|P2HUNTER: "$GetName(h.p)); 
                    hunters++;
                } else {
                    BroadcastMessage("|P4HIDER: "$GetName(h.p)); 
                    hiders++;
                }
                
                total++;
            }
            if(bTimeLimit) {
                timeRemaining = TimeLimit - Loops;
                BroadcastMessage("|P2"$timeRemaining$" seconds remaining for this hunt.");
            }
            BroadcastMessage(hunters@"players are hunting,"@hiders@"are hiding, out of"@total@"total players.");

        } else {
            pp.ClientMessage("No game currently running. Use `mutate hunt.start` to begin.");
            BroadcastMessage("Time to hide: "$TimeToHide);
            BroadcastMessage("Time between rounds (E): "$TimeBetweenRounds);
            BroadcastMessage("Hard Mode: "$bHardMode);
            BroadcastMessage("Speedrun Mode: "$bTimeLimit$" ("$TimeLimit$"s)");
            
        }
    }

    
    if(S ~= "hunt.start" && !bHSOn  ) {
        bHSOn=True;

        BeginHunter(DeusExPlayer(PP));
    }
    
    if(S ~= "hunt.random" && !bHSOn  ) {
        bHSOn=True;
        BeginHunter(GetRandomPlayer());
    }
    
    if(S ~= "hunt.endless" && !bHSOn  ) {
        bHSOn=True;
        bEndless=True;
        bFinalRound=False;
        BeginHunter(GetRandomPlayer());
    }
    
    if(S ~= "hunt.end" && bHSOn && DeusExPlayer(PP).bAdmin) {
        bEndless = False;
        PlayToEveryone(GameOverSnd);
        BroadcastMessage("|P2The hunt was cancelled.");
        CleanupHunter();
    }
    
    if(S ~= "hunt.final" && bHSOn && DeusExPlayer(PP).bAdmin) {
        bFinalRound = True;
        BroadcastMessage("[Hunt] This will be the final round.");
    }
    
    if(Left(s, 9) == "hunt.set " && PP.bAdmin){
        marg = Right(S, Len(S) - 9);
        mval = Splitter(marg, " ", 0);
        mkey = Splitter(marg, " ", 1);
        BroadcastMessage("|P7Hunters setting changed by "$PP.PlayerReplicationInfo.PlayerName$": "$mkey$" = "$mval);
        SetPropertyText(mkey, mval);
        SaveConfig();
    }
    
    if( DeusExPlayer(PP).bAdmin && S ~= "hunt.reset"  && !bHSOn ) {
        BroadcastMessage("Scoreboard reset.");
        ResetScores();
    }
}




function LightUp(DeusExPlayer dxp){
    GetHunterPlayerInfo(dxp).AddLight();
}

function LightOff(DeusExPlayer dxp){
    GetHunterPlayerInfo(dxp).DeleteLight();
}

function PlayToEveryone(sound snd){
    local DeusExPlayer P;
    foreach AllActors(class'DeusExPlayer', p) p.ClientPlaySound(snd);
}

function string Splitter(string s, string at, int index){
    local string outl, outr;
    
    outr = Right(s, Len(s)-instr(s,at)-Len(at));
    outl = Left(s, InStr(s,at));
    
    if(index == 0) return outr;
    else return outl;
}


function debugLog(string ln){
    if(bDebug) Log(ln, 'HUNTDBG');
}
function DeusExPlayer GetRandomPlayer(){
    local DeusExPlayer players[32];
    local int lim, selector;
    local DeusExPlayer potential;
    lim = 0;
    debugLog("Selecting random...");
    foreach AllActors(class'DeusExPlayer', potential){
        if(!potential.isinState('Spectating')){
            players[lim] = potential;
            log(lim$" "$potential);
            lim++;
        }
    }
    debugLog("final limit "$lim);
    
    selector = Rand(lim);
    debugLog("selector "$selector);
    if(players[selector] == None) selector--;
    debugLog("selector after mod "$selector);
    debugLog("Returning "$players[selector].PlayerReplicationInfo.playername);
    return players[selector];
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
    TimeToHide=60
    TimeBetweenRounds=5
    OutputMod=30
    TimeLimitReminder=30
    bPlaySounds=True
    HardModeDamage=10
    HuntBeginSnd=Sound'h_begin'
    HuntRoundStartSnd=Sound'h_huntison'
    HunterCatchSnd=Sound'h_confirmed'
    PlayerCaughtSnd=Sound'h_caught'
    HunterErrorSnd=Sound'h_errored'
    GameOverSnd=Sound'h_gameover'
    HunterLightType=LT_Steady
    HunterLightBrightness=64
    HunterLightRadius=8
    bLighting=True
    bTimeLimit=False
    TimeLimit=600
}

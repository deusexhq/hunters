class CameraTimer extends Actor;
var bool bCamsHooked;
var int loops;
var HuntersMut WorldMutator;

function Timer(){
    local DeusExPlayer DXP;

    Loops++;
    if(WorldMutator.bHuntCamera && WorldMutator.bHookingCams && Loops >= WorldMutator.TimeToHookCams){
        WorldMutator.bHookingCams = False;
        WorldMutator.bCamerasHooked = True;
        WorldMutator.TimeToReleaseCams = WorldMutator.HuntCameraTime + Loops;
        foreach allactors(class'DeusExPlayer',DXP) {
            if(!DXP.isinState('Spectating') && DXP != WorldMutator.LastCaughtPlayer && DXP != WorldMutator.LastCatchPlayer) {
                WorldMutator.LockPlayerCam(DXP, WorldMutator.LastCaughtPlayer);                        
            }
        }
        
    }
    
    if(WorldMutator.bHuntCamera && WorldMutator.bCamerasHooked && Loops >= WorldMutator.TimeToReleaseCams){
        WorldMutator.UnlockPlayersCam();
        WorldMutator.bCamerasHooked=False;
    }
}

defaultproperties
{
    bHidden=True;
}

class LobbyWatcher extends Actor;

var DeusExPlayer dxp;

function PostBeginPlay(){
    SetTimer(1, True);
}

function Timer(){
    if(!DXP.isInState('Spectating')){
        DXP.GoToState('Spectating');
        DXP.ClientMessage("|p3You are in the lobby. Wait your turn!");
    }
}

defaultproperties
{
    bHidden=True
}

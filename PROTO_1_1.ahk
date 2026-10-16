#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
SendMode('Event')
SetKeyDelay(35, 35)

; PROTO 1.1 - portable AutoHotkey client
; F8 = stop, F9 = start all, F12 = emergency exit

spaceOn := false
zOn := false
oneOn := false
spaceHeld := false

mainGui := Gui('+AlwaysOnTop +ToolWindow', 'PROTO 1.1 — Metin2 Assistant')
mainGui.SetFont('s10', 'Segoe UI')
mainGui.MarginX := 18
mainGui.MarginY := 14
mainGui.AddText('w370', 'PROTO 1.1  |  Metin2 Assistant')
mainGui.AddText('w370 cGray', 'Makra klawiatury • F8 STOP • F9 START • F12 WYJŚCIE')
cbSpace := mainGui.AddCheckbox('xm y+16 w350', 'Przytrzymuj SPACJĘ')
cbZ := mainGui.AddCheckbox('xm y+8 w350', 'Klikaj Z co 500 ms')
cbOne := mainGui.AddCheckbox('xm y+8 w350', 'Klikaj 1 co 500 ms')
btnStart := mainGui.AddButton('xm y+16 w175 h34', 'START WSZYSTKO (F9)')
btnStop := mainGui.AddButton('x+8 yp w175 h34', 'STOP (F8)')
btnUpdates := mainGui.AddButton('xm y+10 w175 h30', 'Sprawdź aktualizacje')
btnAbout := mainGui.AddButton('x+8 yp w175 h30', 'O PROTO')
status := mainGui.AddText('xm y+16 w370 cGreen', 'STATUS: MAKRA ZATRZYMANE')
mainGui.AddText('xm y+8 w370 cGray', 'GM / BS / powiadomienia: planowane, jeszcze nieaktywne w 1.0.')

cbSpace.OnEvent('Click', (*) => ToggleSpace())
cbZ.OnEvent('Click', (*) => ToggleZ())
cbOne.OnEvent('Click', (*) => ToggleOne())
btnStart.OnEvent('Click', (*) => StartAll())
btnStop.OnEvent('Click', (*) => StopAll())
btnUpdates.OnEvent('Click', (*) => ShowUpdates())
btnAbout.OnEvent('Click', (*) => MsgBox('PROTO 1.1`nMakra: Spacja, Z, 1, START/STOP i skróty globalne.`n`nAutomatyczne aktualizacje online nie są jeszcze podłączone — wymaga to publicznego adresu pliku wersji.', 'O PROTO', 'Iconi'))
mainGui.OnEvent('Close', (*) => ExitApp())
mainGui.OnEvent('Escape', (*) => ExitApp())

Hotkey('F8', (*) => StopAll())
Hotkey('F9', (*) => StartAll())
Hotkey('F12', (*) => ExitApp())
Hotkey('^!F12', (*) => ExitApp())
SetTimer(RepeatKeys, 500)
OnExit(ReleaseHeldKeys)
mainGui.Show('w410')
UpdateUI()

ToggleSpace() {
    global spaceOn, spaceHeld
    spaceOn := !spaceOn
    if spaceOn && !spaceHeld {
        SendEvent('{Space down}')
        spaceHeld := true
    } else if !spaceOn && spaceHeld {
        SendEvent('{Space up}')
        spaceHeld := false
    }
    UpdateUI()
}
ToggleZ() {
    global zOn
    zOn := !zOn
    UpdateUI()
}
ToggleOne() {
    global oneOn
    oneOn := !oneOn
    UpdateUI()
}
StartAll() {
    global spaceOn, zOn, oneOn, spaceHeld
    spaceOn := true, zOn := true, oneOn := true
    if !spaceHeld {
        SendEvent('{Space down}')
        spaceHeld := true
    }
    UpdateUI()
}
StopAll() {
    global spaceOn, zOn, oneOn, spaceHeld
    spaceOn := false, zOn := false, oneOn := false
    if spaceHeld {
        SendEvent('{Space up}')
        spaceHeld := false
    }
    UpdateUI()
    SoundBeep(900, 120)
}
RepeatKeys() {
    global zOn, oneOn
    if zOn
        SendEvent('z')
    if oneOn {
        ; Send the physical top-row 1 key (scan code 002), which games often handle better.
        SendEvent('{sc002 down}')
        Sleep(35)
        SendEvent('{sc002 up}')
    }
}
UpdateUI() {
    global spaceOn, zOn, oneOn, cbSpace, cbZ, cbOne, status
    cbSpace.Value := spaceOn
    cbZ.Value := zOn
    cbOne.Value := oneOn
    if spaceOn || zOn || oneOn
        status.SetFont('cGreen')
    else
        status.SetFont('cRed')
    status.Text := (spaceOn || zOn || oneOn) ? 'STATUS: MAKRA AKTYWNE' : 'STATUS: MAKRA ZATRZYMANE'
}
ShowUpdates() {
    MsgBox('PROTO 1.1`n`nNie można jeszcze sprawdzić aktualizacji online, ponieważ PROTO nie ma skonfigurowanego publicznego adresu źródła wersji.`n`nTo nie oznacza, że na pewno masz najnowszą wersję. Po opublikowaniu pliku wersji podłączymy prawdziwe sprawdzanie.', 'Aktualizacje PROTO', 'Icon!')
}
ReleaseHeldKeys(*) {
    global spaceHeld
    if spaceHeld
        SendEvent('{Space up}')
}

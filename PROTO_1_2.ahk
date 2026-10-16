#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
SendMode('Event')
SetKeyDelay(35, 35)

; PROTO 1.2 - portable AutoHotkey client
; F8 = stop, F9 = start all, F12 = emergency exit

spaceOn := false
zOn := false
oneOn := false
spaceHeld := false

mainGui := Gui('+AlwaysOnTop +ToolWindow', 'PROTO 1.2 — Metin2 Assistant')
mainGui.SetFont('s10', 'Segoe UI')
mainGui.MarginX := 18
mainGui.MarginY := 14
mainGui.AddText('w370', 'PROTO 1.2  |  Metin2 Assistant')
mainGui.AddText('w370 cGray', 'Makra klawiatury • F8 STOP • F9 START • F12 WYJŚCIE')
cbSpace := mainGui.AddCheckbox('xm y+16 w350', 'Przytrzymuj SPACJĘ')
cbZ := mainGui.AddCheckbox('xm y+8 w350', 'Klikaj Z co 500 ms')
cbOne := mainGui.AddCheckbox('xm y+8 w350', 'Klikaj 1 co 500 ms')
btnStart := mainGui.AddButton('xm y+16 w175 h34', 'START WSZYSTKO (F9)')
btnStop := mainGui.AddButton('x+8 yp w175 h34', 'STOP (F8)')
btnUpdates := mainGui.AddButton('xm y+10 w175 h30', 'Sprawdź aktualizacje')
btnAbout := mainGui.AddButton('x+8 yp w175 h30', 'O PROTO')
status := mainGui.AddText('xm y+16 w370 cGreen', 'STATUS: MAKRA ZATRZYMANE')
mainGui.AddText('xm y+8 w370 cGray', 'GM / BS / powiadomienia: planowane, jeszcze nieaktywne w 1.2.')

cbSpace.OnEvent('Click', (*) => ToggleSpace())
cbZ.OnEvent('Click', (*) => ToggleZ())
cbOne.OnEvent('Click', (*) => ToggleOne())
btnStart.OnEvent('Click', (*) => StartAll())
btnStop.OnEvent('Click', (*) => StopAll())
btnUpdates.OnEvent('Click', (*) => ShowUpdates())
btnAbout.OnEvent('Click', (*) => MsgBox('PROTO 1.2`nMakra: Spacja, Z, 1, START/STOP i skróty globalne.`n`nSprawdzanie wersji odbywa się online przez repozytorium PROTO.', 'O PROTO', 'Iconi'))
mainGui.OnEvent('Close', (*) => ExitApp())
mainGui.OnEvent('Escape', (*) => ExitApp())

Hotkey('F8', (*) => StopAll())
Hotkey('F9', (*) => StartAll())
Hotkey('F12', (*) => ExitApp())
Hotkey('^!F12', (*) => ExitApp())
SetTimer(RepeatKeys, 500)
SetTimer(CheckUpdatesOnStartup, -1800)
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
CheckUpdatesOnStartup() {
    ; Sprawdzenie po uruchomieniu; pobranie wymaga potwierdzenia użytkownika.
    CheckUpdates(true)
}
ShowUpdates() {
    CheckUpdates(false)
}
CheckUpdates(silent := false) {
    currentVersion := "1.2"
    versionUrl := "https://raw.githubusercontent.com/kewin8763-dev/PROTO/main/version.json"
    try {
        req := ComObject("WinHttp.WinHttpRequest.5.1")
        req.SetTimeouts(3000, 3000, 3000, 7000)
        req.Open("GET", versionUrl, false)
        req.Send()
        if (req.Status != 200)
            throw Error("HTTP " req.Status)
        data := req.ResponseText
        if !RegExMatch(data, '"version"\s*:\s*"([^"\r\n]+)"', &ver)
            throw Error("Nie znaleziono numeru wersji.")
        latestVersion := ver[1]
        message := "Dostępna wersja PROTO: " latestVersion
        if RegExMatch(data, '"message"\s*:\s*"([^"\r\n]*)"', &msg)
            message .= "`n" msg[1]
        if (latestVersion = currentVersion) {
            if !silent
                MsgBox("Masz najnowszą wersję PROTO (" currentVersion ").", "Aktualizacje PROTO", "Iconi")
            return
        }
        downloadUrl := ""
        if RegExMatch(data, '"download_url"\s*:\s*"([^"\r\n]*)"', &dl)
            downloadUrl := dl[1]
        if (downloadUrl = "") {
            if !silent
                MsgBox(message "`n`nWykryto inną wersję, ale w version.json nie ustawiono download_url.", "Aktualizacje PROTO", "Icon!")
            return
        }
        answer := MsgBox(message "`n`nPobrać i zainstalować aktualizację? Makra zostaną zatrzymane na czas aktualizacji.", "Aktualizacja PROTO", "YesNo Icon?")
        if (answer != "Yes")
            return
        DownloadAndInstall(downloadUrl, latestVersion)
    } catch as err {
        if !silent
            MsgBox("Nie udało się sprawdzić aktualizacji online.`nSprawdź połączenie z internetem.`n`nSzczegóły: " err.Message, "Aktualizacje PROTO", "Icon!")
    }
}
DownloadAndInstall(url, latestVersion) {
    global mainGui
    try {
        if !InStr(url, "https://raw.githubusercontent.com/") || !RegExMatch(url, "\.ahk(?:\?.*)?$")
            throw Error("Link pobierania musi prowadzić do pliku .ahk w raw.githubusercontent.com.")
        req := ComObject("WinHttp.WinHttpRequest.5.1")
        req.SetTimeouts(5000, 5000, 5000, 20000)
        req.Open("GET", url, false)
        req.Send()
        if (req.Status != 200)
            throw Error("Pobieranie nie powiodło się. HTTP " req.Status)
        body := req.ResponseText
        if (StrLen(body) < 1000 || !InStr(body, "#Requires AutoHotkey v2.0") || !InStr(body, "PROTO"))
            throw Error("Pobrany plik nie wygląda na prawidłowy skrypt PROTO. Niczego nie zmieniono.")

        currentPath := A_ScriptFullPath
        folder := A_ScriptDir
        newPath := folder "\PROTO_update.ahk"
        tempPath := folder "\PROTO_update.download.tmp"
        if FileExist(newPath)
            FileDelete(newPath)
        if FileExist(tempPath)
            FileDelete(tempPath)
        FileAppend(body, tempPath, "UTF-8-RAW")
        if !FileExist(tempPath) || FileGetSize(tempPath) < 1000
            throw Error("Nie można zapisać pobranego pliku. Sprawdź uprawnienia folderu.")
        FileMove(tempPath, newPath, 1)

        ; Helper .cmd czeka na zamknięcie tego procesu, robi kopię i podmienia plik.
        helperPath := folder "\PROTO_updater.cmd"
        backupPath := currentPath ".bak"
        cmd := '@echo off`r`n'
        cmd .= 'setlocal`r`n'
        cmd .= 'timeout /t 2 /nobreak >nul`r`n'
        cmd .= 'copy /y "' currentPath '" "' backupPath '" >nul`r`n'
        cmd .= 'copy /y "' newPath '" "' currentPath '" >nul`r`n'
        cmd .= 'if errorlevel 1 (echo Aktualizacja nie powiodla sie. Plik nowej wersji: ' newPath ' & pause & exit /b 1)`r`n'
        cmd .= 'start "" "' currentPath '"`r`n'
        cmd .= 'del "%~f0"`r`n'
        FileAppend(cmd, helperPath, "UTF-8-RAW")
        StopAll()
        Run('"' helperPath '"', folder, "Hide")
        MsgBox("Pobrano PROTO " latestVersion ". Program zamknie się i uruchomi ponownie po aktualizacji.", "Aktualizacja PROTO", "Iconi")
        ExitApp()
    } catch as err {
        MsgBox("Aktualizacja nie została zainstalowana.`n" err.Message, "Aktualizacje PROTO", "Icon!")
    }
}

ReleaseHeldKeys(*) {
    global spaceHeld
    if spaceHeld
        SendEvent('{Space up}')
}

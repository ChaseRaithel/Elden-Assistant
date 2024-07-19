; AutoHotkey v2.0
; Elden_Assistant.ahk
; Script for Elden Ring on PC by Sevenmirror
;
; Modify/share/copy to hearts content.  Just give me creds.  Thanks.

#Requires AutoHotkey v2.0
SetWorkingDir A_ScriptDir
SetTitleMatchMode 2 ; Match window titles partially
WinTitle := "ELDEN RING™"


; Create a default config file if it doesn't exist
if !FileExist("config.ini") {
    CreateDefaultConfig()
}

CreateDefaultConfig() {
    defaultConfig := "
    (
        [Hotkeys]
        equipmentKey=!CapsLock
        spellKey=RButton
        skillKey=Forward
        [SpellHotkeys]
        Spell1=!1
        Spell2=!2
        Spell3=!3
        Spell4=!4
        Spell5=!5
        Spell6=!6
        Spell7=!7
        Spell8=!8
        Spell9=!9
        Spell10=!0
        [Setup]
        totalSpellsEquipped=8
    )"
    
    FileAppend(defaultConfig, "config.ini")
}

!v::
{
	MsgBox("Paused`nRight click icon to continue", "")
	toggle:=0
	Send "{shift up}"
	;Suspend
	;exitapp
	Pause
}

; Hotkey: Ctrl + M Opens interactive map on second monitor
^m:: {
    ; URL of your Elden Ring interactive map
    url := "https://eldenring.wiki.fextralife.com/Interactive+Map"

    ; Open Microsoft Edge with the specified URL
    ; Change to your desired browser if you prefer a different one
    Run("msedge.exe --new-window " url)
    
    ; Wait for the window to open
    WinWait("ahk_exe msedge.exe")
    
    ; Get the last active window (which should be the newly opened Edge)
    edgeWindow := WinGetID("A")
    
    ; Get information about the second monitor
    left := 0
    top := 0
    right := 0
    bottom := 0
    MonitorGet(2, &left, &top, &right, &bottom)
    
    ; Move the window to the second monitor
    WinMove(left, top, , , edgeWindow)
    
    ; Maximize the window
    WinMaximize(edgeWindow)
}

; GUI for editing the config file and saving the config file

^f12::{
    MsgBox("display gui")
    DisplayConfigGUI()
}

ReadConfigValues() {
    config := Map()
    config["totalSpellsEquipped"] := IniRead("config.ini", "Setup", "totalSpellsEquipped", 8)
    Loop 10 {
        config["Spell" . A_Index] := IniRead("config.ini", "SpellHotkeys", "Spell" . A_Index, "!" . A_Index)
    }
    config["equipmentKey"] := IniRead("config.ini", "Hotkeys", "equipmentKey", "!CapsLock")
    config["spellKey"] := IniRead("config.ini", "Hotkeys", "spellKey", "RButton")
    config["skillKey"] := IniRead("config.ini", "Hotkeys", "skillKey", "Forward")
    return config
}

DisplayConfigGUI() {
    config := ReadConfigValues()
    myGui := Gui()
    myGui.Add("Text", "x10 y10", "Total Spells Equipped:")
    myGui.Add("Edit", "x150 y10 w50 vTotalSpells", config["totalSpellsEquipped"])
    
    Loop 10 {
        myGui.Add("Text", "x10 y" . (40 + A_Index * 30), "Spell " . A_Index . " Hotkey:")
        myGui.Add("Edit", "x150 y" . (40 + A_Index * 30) . " w100 vSpell" . A_Index, config["Spell" . A_Index])
    }
    
    myGui.Add("Button", "x10 y370 w100", "Save").OnEvent("Click", (*) => SaveConfig(myGui))
    myGui.Add("Button", "x120 y370 w100", "Cancel").OnEvent("Click", (*) => myGui.Destroy())
    
    myGui.Show()
}
SaveConfig(savedGui)
{
    IniWrite(savedGui['TotalSpells'].Value, "config.ini", "Setup", "totalSpellsEquipped")
    Loop 10 {
        IniWrite(savedGui['Spell' . A_Index].Value, "config.ini", "SpellHotkeys", "Spell" . A_Index)
    }
    
    MsgBox("Configuration saved successfully!")
    savedGui.Destroy()
    eldenbot_load_hotkeys()
}







WinWait "ELDEN RING™"
WinActivate "ELDEN RING™"



#HotIf WinActive(WinTitle)

; Dynamic setting hotkeys for spell/incantation casting using config.ini
eldenbot_load_hotkeys()

eldenbot_load_hotkeys() {
    Loop 10 {
        hotkeyString := IniRead("config.ini", "SpellHotkeys", "Spell" . A_Index, "!" . A_Index)
        Hotkey "*" . hotkeyString, ((index) => (*) => CastSpell(index))(A_Index)
    }
}



global totalSpellSlots := IniRead("config.ini", "Setup", "totalSpellsEquipped", 10) ; Modify this using the config file or it will break

global hasCalibrated := false
global spellQueue := []
global isProcessingQueue := false

CastSpell(targetSlot, castButton := "RButton") {
    spellQueue.Push(targetSlot)
    if (!isProcessingQueue) {
        SetTimer ProcessSpellQueue, -10
    }
}

ProcessSpellQueue() {
    global currentSpellSlot, totalSpellSlots, hasCalibrated, isProcessingQueue
    isProcessingQueue := true

    while (spellQueue.Length > 0) {
        targetSlot := spellQueue.RemoveAt(1)

        if (!hasCalibrated) {
            Send "{f down}"
            Sleep 520
            Send "{f up}"
            Sleep 50
            currentSpellSlot := 1
            hasCalibrated := true
        }

        pressesNeeded := Mod(targetSlot - currentSpellSlot + totalSpellSlots, totalSpellSlots)
        
        Loop pressesNeeded {
            Send "{f down}"
            Sleep 22
            Send "{f up}"
            Sleep 22
        }

        Send "{RButton down}"
        Sleep 22
        Send "{RButton up}"
        Sleep 150  ; Increased delay between casts

        currentSpellSlot := targetSlot
    }

    isProcessingQueue := false
}

$f::
{
    global currentSpellSlot, totalSpellSlots
    Send "{f down}"
    pressStartTime := A_TickCount
    KeyWait "f"
    pressDuration := A_TickCount - pressStartTime
    Send "{f up}"
    
    if (pressDuration > 500) {
        currentSpellSlot := 1
    } else {
        currentSpellSlot := Mod(currentSpellSlot, totalSpellSlots) + 1
    }
}





F12:: ;Easy way to reload script after saving changes.  Change Fkey if you're already using it for something.
 {
    Reload
 }


; Pressing capslock once will bring up inventory.  Pressing twice will select your first talisman for fast switching.

capslock:: 
KeyWinC(ThisHotkey)  ; This is a named function hotkey
{
    static winc_presses := 0
    if winc_presses > 0 ; SetTimer already started, so we log the keypress instead.
    {
        winc_presses += 1
        return
    }
    ; Otherwise, this is the first press of a new series. Set count to 1 and start
    ; the timer:
    winc_presses := 1
    SetTimer After400, -270 ; Wait for more presses within a xxx millisecond window.

    After400()  ; This is a nested function.
    {
		
        if winc_presses = 1 ; The key was pressed once.
        {
			
            SetKeyDelay 40, 25
			SendEvent "{esc down}" "{esc up}" "{down down}" "{down up}" "{down down}" "{down up}" "{e down}" "{e up}" "{x down}" "{x up}" 
			sleep 50
		}
        else if winc_presses = 2 ; The key was pressed twice.
        {
            SetKeyDelay 40,25
			SendEvent "{esc down}" "{esc up}" "{e down}" "{e up}" "{down down}" "{down up}" "{down down}" "{down up}" "{down down}" "{down up}" "{e down}" "{e up}"
			sleep 50
        }
        else if winc_presses > 2
        {
            ;MsgBox "Three or more clicks detected."
        }
        ; Regardless of which action above was triggered, reset the count to
        ; prepare for the next series of presses:
        winc_presses := 0
    }
	
}

equipment_key := IniRead("config.ini", "Hotkeys", "equipmentKey", "!CapsLock")

!capslock::eldenmenu()

eldenmenu()
    {
    SetKeyDelay 40,20
    SendEvent "{esc down}" "{esc up}" "{e down}" "{e up}"
    sleep 50
}
^esc:: ; (Control + Escape) Fast quit to main menu hotkey
{
    Actions := [
        "{Escape down}","{Escape up}",
        "{Up down}","{Up up}",
        "{e down}","{e up}",
        "{z down}","{z up}",
        "{e down}","{e up}",
        "{Left down}","{Left up}",
        "{e down}","{e up}",
        "{e down}","{e up}",
        "{e down}","{e up}"
    ]

    for _, Action in Actions
    {
        Send Action
        Sleep 60
    }
    Sleep 10
}







; Bot rune farm at grace by bird.  Point it towards the albenarics.  Only equip gold wave weapon in right hand.
; remove the /* and */ and press F12 to reload script.  Then control + v to start.  Alt + v will pause the script.
; Positioning is important to get this to run correctly.  Make sure you are at the top part of the grace, as this
; script is basic, and just runs in a straight line pressing "w", uses the Ash of War, then comes back in a straight
; line press "s".  It will then fire off rapid "e" keys trying to snag the grace at the tail end of it's return.
; It works... but eventually it will probably get off track.

/*
^v:: ; Control + V
{
global skillbutton:="u" ;modify this to change to your skill button key
global lap:=0
global lap2:=0
global southDelay:=2913.9
loop
	{
		Send "{e down}"
		sleep 210
		Send "{e up}"
		sleep 2700
		loop 2 {
		Send "{q down}"
		sleep 500
		Send "{q up}"
		sleep 500
		lap:=lap+1
		lap2:=lap2+1
	}
			sleep 1200
			sleep 500
			Send "{shift down}"
			sleep 100
			Send "{w down}"
			
			sleep 2840 ;running
			Send "{w up}"
			sleep 200
			Send "{" skillKey . " down}"
			sleep 1100
			Send "{" skillKey . " up}"
			sleep 2700
			HoldKeyWithIntervalKey("s",3170,"e",500,30)
			sleep 400
			Send "{shift up}"
			sleep 1200
	}
}
*/

; Function for the bot
HoldKeyWithIntervalKey(key, duration, intervalKey, intervalDuration, interval)
{
	Send "{" . key . " down}"
	sleep (duration - intervalDuration)
	loop (intervalDuration / interval)
	{
		Send "{" . intervalKey . " down}"
		sleep 20
		Send "{" . intervalKey . " up}"
		sleep (interval - 50)
	}
	
	Send "{" . key . " up}"
}


/*

Weird bug with Magma breath incantations.  If you have catch flame highlighted and magma breath directly
after it, it will jump cast catch flame into magma breath with no delay.  I've noticed you need to cast
magma breath normally first.  Then this will work indefinatly until you cast another spell outside of
these two.

Best results is use the hotkey to have the script jump cast catch flame for you, and keep spamming your cast
key.

If you want to see something REALLY freaky, do this exploit with the staff that casts both spells and
incantations.  It will leave a severed dragon head on the ground every time you do it.  Whats wild is mobs
will actually walk around the heads and treat them as threats.

*/
; Set a custom delay (in milliseconds)
customDelay := 50
actions := [
    "{space down}",
	"{space up}",
	"{RButton down}", ; Press the left mouse button
    "{RButton up}", ; Release the left mouse button
    "{f down}",
	"{f up}",
	"{RButton down}", ; Press the left mouse button
    "{RButton up}", ; Release the left mouse button
	]

^Space:: {  ; Control + Space to execute the jump cast catch flame, incantation swap, cast maga (or next incantation in your list)
	KeyWait "Control"
	KeyWait "space"

    ; Perform the actions
    for Index, action in actions
    {
        Send action
		Sleep customDelay
    }

    ; Restore input
    
	;BlockInput False
	}

; Elden Ring Save File Backup Script
; Author: Sevenmirror + ChatGPT
; Version: 1.9
; F9 will make a copy of your save game with any name attached to it.
; Nice way to make multiple save games before each boss fight to practice them anytime


ERSaveDir := A_AppData . "\EldenRing\" ; Set your Elden Ring save file directory
global BossName:=""
global BackupName:=""
Loop Files, ERSaveDir "\*", "D"
	{
		; Save the name of the first directory found
		SplitPath(A_LoopFilePath, &name)
		ERSaveDir := ERSaveDir . name
		break  ; Exit the loop after finding the first directory
	}
PerformBackup(BossName := "") {
	BossName := InputBox("Please enter a Boss Name or Save Name.", "Save", "w540 h180")
	;if BossName.Result = "Cancel" { BossName := "" }
    ; If the user didn't enter a name, use a generic backup name with date and time
    if (BossName = "") {
        BackupName := FormatTime(,"Time")
        BackupName := "ER0000_Backup_" . BackupName . ".sl2"
    } else {
        BackupName := "ER0000_Backup_" FormatTime(,"Time") "_" . BossName.Value . ".sl2"
    }

    ; Backup the save file
    if (FileExist(ERSaveDir . "\ER0000.sl2")) {
		BackupName:= STRreplace(BackUpName,":","")
        FileCopy ERSaveDir . "\ER0000.sl2", ERSaveDir . "\" . BackupName
        MsgBox "Backup completed successfully! Saved as " . BackupName . "."
    } else {
        MsgBox " " . ERSaveDir . "`nElden Ring save file not found. Make sure the path is correct."
    }
}

; Create a hotkey to run the backup function when you press F9
F9:: {
    PerformBackup()
}
/*
WheelUp:: {
 Send "{f down}"
 sleep(random(533,555))
 Send "{f up}"
 }
 */

 
 sleep 500
 tooltip "loaded!"
 sleep 500
 ToolTip
Sub ShowProfileScreen(profiles) as Object
  profileScreen = CreateObject("roPosterScreen")
  port = CreateObject("roMessagePort")
  profileScreen.SetMessagePort(port)
  profileScreen.SetListStyle("arced-square")
  profileScreen.SetListDisplayMode("zoom-to-fill")
  profileScreen.setContentList(profiles)
  
  profileScreen.Show()

  ret = {}

  s = ""
  While True
    msg = wait(1000, port)
    if type(msg) = "roPosterScreenEvent" then
      If msg.isScreenClosed() Then
        ret.action = "exit"
        return ret
      Else If msg.isListItemSelected() then
        profile = profiles.GetEntry(msg.GetIndex())
        if profile.restricted then
          pin = ShowPinEntryDialog()
          if pin <> "" then
            token = RequestToken(profile.title, pin)
            if token <> invalid and token <> "" then
              profile.token = token
              ret.action = "profile"
              ret.profile = profile
              return ret
            else
              ShowMessageDialog("Invalid pin")
            end if
          end if
        else
          token = RequestToken(profile.title, invalid)
          if token <> invalid and token <> "" then
            profile.token = token
            ret.action = "profile"
            ret.profile = profile
            return ret
          else
            ShowMessageDialog("Unexpected token error")
          end if
        end if
      Else If msg.isRemoteKeyPressed() then
        if msg.GetIndex() = 10 then
          s = s + "s"
        else if msg.GetIndex() = 13 then
          s = s + "p"
        end if
      end if
    else
      if s = "s" or s = "ss" then
        ret.action = "config"
        return ret
      else if s.Len() >= 4 then
        profile = GetProfile(s) 
        if profile <> invalid then
          profile.token = s
          ret.action = "profile"
          ret.profile = profile
          return ret
        end if
      end if
      s = ""
    End If
  End While
End Sub

Function ShowPinEntryDialog() As string
  port = CreateObject("roMessagePort")
  screen = CreateObject("roPinEntryDialog")

  screen.SetMessagePort(port)
  screen.SetTitle("Please enter your pin")
  screen.SetNumPinEntryFields(4)
    
  screen.AddButton(1, "OK")
  screen.AddButton(2, "CANCEL")
    
  screen.EnableBackButton(true)
  screen.Show()

  while true
    msg = wait(0, screen.GetMessagePort())
    if type(msg) = "roPinEntryDialogEvent" then
      if msg.isScreenClosed() then
        return ""         
      else if msg.isButtonPressed() then
        if msg.GetIndex() = 1 then
          screen.Close()
		  return screen.Pin()
		else if msg.GetIndex() = 2 then
		  screen.Close()
		  return ""
        end if
      end if
    end if
  end while
End Function

Sub Main()
  initTheme()
  
  canvas = CreateObject("roImageCanvas")
  port = CreateObject("roMessagePort")
  canvas.SetMessagePort(port)
  canvas.SetLayer(0, {Color:"#FF000000", CompositionMode:"Source"})
  canvas.SetRequireAllImagesToDraw(true)
  canvas.Show()
  
  host = GetHost()
  if VerifyHost(host) = false then
    host = FindHost()
    if VerifyHost(host) = true then
      SaveHost(host)
    else
      if ShowConfigScreen() = true then
        host = GetHost()
      else
        return
      end if
    end if
  end if
  
  print host
  
  while true
    connected = false
    version = GetServerApiVersion(host)
    if version = invalid then
      if ShowUnableToConnectDialog("Unable to connect to the server") = false then
        return
      end if
    else if version >= 2.0 then
      ' TODO better message
      ShowUnableToConnectDialog("This Roku app is outdated and is incompatible with your server.  Please update this Roku app to the latest version.")
      return
    else if version < 1.0 then
      ' TODO better message
      ShowUnableToConnectDialog("Your server is outdated and incompatible with this Roku app.  Please update your server to the latest version.")
      return
    else
      connected = true
    end if
    
    if connected = true then
      profiles = GetProfiles()
      if profiles = invalid or profiles.Count() = 0 then
        ShowMessageDialog("No profiles are available.  Please configure a profile by visiting " + GetBaseUrl(GetHosts()) + " from your web browser.")
        return
      'else if profiles.Count() = 1 and profiles.Peek().restricted = false then
      '  profile = profiles.Peek()
      '  token = RequestToken(profile.title, invalid)
      '  if token <> invalid and token <> "" then
      '    profile.token = token
      '    LaunchProfile(profile)
      '    return
      '  end if
      else
        ret = ShowProfileScreen(profiles)
        if ret.action = "exit" then
          return
        else if ret.action = "config" then
          ShowConfigScreen()
        else if ret.action = "profile" and ret.profile <> invalid then
          LaunchProfile(ret.profile)
        end if
      end if
    end if
  end while
End Sub

Sub FindHost() as String
  'TODO: implement network discovery
  return ""
End Sub

Sub VerifyHost(host as String) as Boolean
  if host = invalid or host = "" then
    return false
  else
    version = GetServerApiVersion(host)
    if version = invalid then
      return false
    else
      return true
    end if
  end if
End Sub

Sub LaunchProfile(profile) 
  airings = GetAirings(profile.token, 2, 0)
  if airings <> invalid and airings.Count() > 0 then
    ShowGuideScreen(profile)
  else
    ShowContentScreen(profile, true)
  end if
End Sub

Function ShowUnableToConnectDialog(msg as String) As Boolean
  port = CreateObject("roMessagePort")
  dialog = CreateObject("roMessageDialog")
  dialog.SetMessagePort(port)
  dialog.SetTitle("")
  dialog.SetText(msg)
 
  dialog.AddButton(1, "Try Again")
  dialog.AddButton(2, "Configure")
  dialog.AddButton(3, "Exit")
  dialog.EnableBackButton(true)
  dialog.Show()
  While True
    dlgMsg = wait(0, dialog.GetMessagePort())
    If type(dlgMsg) = "roMessageDialogEvent" then
      if dlgMsg.isButtonPressed() then
        if dlgMsg.GetIndex() = 1 then
          dialog.Close()
          return true
        else if dlgMsg.GetIndex() = 2 then
          dialog.Close()
          ShowConfigScreen()
          return true
        else if dlgMsg.GetIndex() = 3 then
          dialog.Close()
          return false
        end if
      else if dlgMsg.isScreenClosed() then
        return false
      end if
    end if
  end while
End Function

Sub initTheme()

  app = CreateObject("roAppManager")
  theme = CreateObject("roAssociativeArray")

  theme.BackgroundColor = "#363636"

  theme.OverhangPrimaryLogoOffsetSD_X = "20"
  theme.OverhangPrimaryLogoOffsetSD_Y = "3"

  theme.OverhangPrimaryLogoOffsetHD_X = "30"
  theme.OverhangPrimaryLogoOffsetHD_Y = "6"

  theme.OverhangSliceSD = "pkg:/images/overhang_sd.png"
  theme.OverhangSliceHD = "pkg:/images/overhang_hd.png"
  theme.OverhangPrimaryLogoSD = "pkg:/images/Deeviar269X85.png"
  theme.OverhangPrimaryLogoHD = "pkg:/images/Deeviar395X125.png"

  ' D0D0D0
  theme.ButtonMenuNormalText = "#ECE1CA"

  theme.BreadcrumbDelimiter = "#ECE1CA"
  theme.BreadcrumbTextLeft = "#ECE1CA"
  theme.BreadcrumbTextRight = "#ECE1CA"

  theme.ListItemText = "#ECE1CA"
  theme.ListScreenDescriptionText = "#ECE1CA"
  theme.ListScreenTitleColor = "#ECE1CA"

  theme.SpringboardActorColor = "#ECE1CA"
  theme.SpringboardAlbumColor = "#ECE1CA"
  theme.SpringboardAlbumLabelColor = "#ECE1CA"
  theme.SpringboardArtistColor = "#ECE1CA"
  theme.SpringboardArtistLabelColor = "#ECE1CA"
  theme.SpringboardDirectorColor = "#ECE1CA"
  theme.SpringboardDirectorLabelColor = "#ECE1CA"
  theme.SpringboardDirectorPrefixText = "#ECE1CA"
  theme.SpringboardGenreColor = "#ECE1CA"
  theme.SpringboardRuntimeColor = "#ECE1CA"
  theme.SpringboardSynopsisColor = "#ECE1CA"
  theme.SpringboardTitleText = "#ECE1CA"

  theme.ParagraphBodyText = "#ECE1CA"
  theme.ParagraphHeaderText = "#ECE1CA"

  theme.PosterScreenLine1Text = "#ECE1CA"
  theme.PosterScreenLine2Text = "#ECE1CA"

  app.SetTheme(theme)

End Sub



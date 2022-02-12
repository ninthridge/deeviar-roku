Sub ShowSpringboardStationScreen(profile, station)
  springBoardScreen = CreateObject("roSpringboardScreen")
  port = CreateObject("roMessagePort")
  springBoardScreen.SetMessagePort(port)

  springBoardScreen.SetPosterStyle("rounded-square-generic")

  springBoardScreen.SetStaticRatingEnabled(False)

  springBoardScreen.AddButton(1, "Watch")
  
  springBoardScreen.SetContent(station)
  springBoardScreen.Show()

  ' TODO: implement guide refresh logic

  While True
    msg = wait(0, port)
    if type(msg) = "roSpringboardScreenEvent" then
      If msg.isScreenClosed() Then
        StopStream(profile.token)
        station.Stream = invalid
        Return
      Elseif msg.isButtonPressed()
        If msg.GetIndex() = 1 then
          PlayStation(profile, station, invalid)
        End If
      End If
    End If
  End While
End Sub


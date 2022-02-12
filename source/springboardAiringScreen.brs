Sub ShowSpringboardAiringScreen(profile, station, airing) as Boolean
  springBoardScreen = CreateObject("roSpringboardScreen")
  port = CreateObject("roMessagePort")
  springBoardScreen.SetMessagePort(port)

  springBoardScreen.SetPosterStyle("rounded-square-generic")
  
  springBoardScreen.SetStaticRatingEnabled(False)

  serverDate = GetServerDate()
  airingStartDate = CreateObject("roDateTime")
  airingStartDate.FromISO8601String(airing.start)
  airingEndAsSeconds = airingStartDate.AsSeconds() + airing.duration
  
  stream = GetStream(profile.token, station.id)
  
  if airingStartDate.AsSeconds() < (serverDate.AsSeconds() - (serverDate.AsSeconds() mod 1800) + 1800) then
    springBoardScreen.AddButton(1, "Watch")
    
    if stream <> invalid then
      streamStartedDate = CreateObject("roDateTime")
      streamStartedDate.FromISO8601String(stream.started)
      if airingStartDate.AsSeconds() - streamStartedDate.AsSeconds() >= 60 then
        springBoardScreen.AddButton(2, "Watch From Beginning")
      end if
    end if
  end if
  
  if airing.timerIds = invalid or airing.timerIds.Count() = 0 then
    if serverDate.AsSeconds() < airingEndAsSeconds then
      springBoardScreen.AddButton(3, "Record")
    end if
  else
    springBoardScreen.AddButton(4, "Delete Timer")
  end if
  
  springBoardScreen.SetContent(airing)
  springBoardScreen.Show()

  While True
    msg = wait(0, port)
    if type(msg) = "roSpringboardScreenEvent" then
      If msg.isScreenClosed() Then
        if station.Stream <> invalid then
          StopStream(profile.token)
          station.Stream = invalid
        end if
        Return false
      Elseif msg.isButtonPressed()
        If msg.GetIndex() = 1 then
          PlayStation(profile, station, invalid)
        ElseIf msg.GetIndex() = 2 then
          streamStartedDate = CreateObject("roDateTime")
          streamStartedDate.FromISO8601String(stream.started)
          playStart = (airingStartDate.AsSeconds() - streamStartedDate.AsSeconds()) - 60
          PlayStation(profile, station, playStart)
        ElseIf msg.GetIndex() = 3 then
          if ShowRecordDialog(profile, airing) then
            ShowMessageDialog("Your recording has been successfully scheduled")
            Return true
          end if
        ElseIf msg.GetIndex() = 4 then
          for each timerId in airing.timerIds
            DeleteTimer(profile.token, timerId)
          end for
          ShowMessageDialog("Your timer has been successfully deleted")
          Return true
        End If
      End If
    End If
  End While
End Sub

Sub ShowRecordDialog(profile, airing) As Boolean
  port = CreateObject("roMessagePort")
  dialog = CreateObject("roMessageDialog")
  dialog.SetMessagePort(port)
  dialog.SetTitle("")
  dialog.SetText("")
 
  dialog.AddButton(1, "Record once")
  dialog.AddButton(2, "Record all")
  dialog.AddButton(3, "Record daily at this time")
  dialog.AddButton(4, "Record weekdays at this time")
  dialog.AddButton(5, "Record weekly at this time")
  dialog.AddButton(10, "Cancel")
  dialog.EnableBackButton(true)
  dialog.Show()
  While True
    dlgMsg = wait(0, dialog.GetMessagePort())
    If type(dlgMsg) = "roMessageDialogEvent"
      if dlgMsg.isButtonPressed()
        if dlgMsg.GetIndex() = 1 then
          CreateTimer(profile.token, airing.id, "Once")
          ' TODO: Error handling
          Return true
        else if dlgMsg.GetIndex() = 2 then
          CreateTimer(profile.token, airing.id, "Title")
          ' TODO: Error handling
          Return true
        else if dlgMsg.GetIndex() = 3 then
          CreateTimer(profile.token, airing.id, "TitleDaily")
          ' TODO: Error handling
          Return true
        else if dlgMsg.GetIndex() = 4 then
          CreateTimer(profile.token, airing.id, "TitleWeekdays")
          ' TODO: Error handling
          Return true
        else if dlgMsg.GetIndex() = 5 then
          CreateTimer(profile.token, airing.id, "TitleWeekly")
          ' TODO: Error handling
          Return true
        else if dlgMsg.GetIndex() = 10 then
          dialog.Close()
          return false
        end if
      else if dlgMsg.isScreenClosed() then
        return false
      end if
    end if
  end while
End Sub
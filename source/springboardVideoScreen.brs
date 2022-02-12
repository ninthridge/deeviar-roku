Sub ShowSpringboardVideoScreen(profile, video) as Boolean
  springBoardScreen = CreateObject("roSpringboardScreen")
  port = CreateObject("roMessagePort")
  springBoardScreen.SetMessagePort(port)

  if video.type <> invalid then
    if video.type = "Movie" then
      springBoardScreen.SetPosterStyle("multiple-portrait-generic")
    else
      springBoardScreen.SetPosterStyle("rounded-rect-16x9-generic")
    end if
  end if

  springBoardScreen.SetStaticRatingEnabled(False)

  springBoardScreen.Show()

  SetSpringboardVideoScreenContent(profile, springBoardScreen, video)

  refresh = false

  While True
    msg = wait(0, port)
    if type(msg) = "roSpringboardScreenEvent" then
      If msg.isScreenClosed() Then
        Return refresh
      Elseif msg.isButtonPressed()
        If msg.GetIndex() = 0 then
          PlayVideo(profile, video, video.bookmarkPosition)
          SetSpringboardVideoScreenContent(profile, springBoardScreen, video)
          refresh = true
        Elseif msg.GetIndex() = 1 then
          PlayVideo(profile, video, 0)
          SetSpringboardVideoScreenContent(profile, springBoardScreen, video)
          refresh = true
        Elseif msg.GetIndex() = 2 then
          Unfavorite(profile.token, video.id)
          video.favorite = false
          SetSpringboardVideoScreenContent(profile, springBoardScreen, video)
          refresh = true
        Elseif msg.GetIndex() = 3 then
          Favorite(profile.token, video.id)
          video.favorite = true
          SetSpringboardVideoScreenContent(profile, springBoardScreen, video)
          refresh = true
        Elseif msg.GetIndex() = 5 then
          if ShowDeleteConfirmationDialog() then
            DeleteVideo(profile.token, video.id)
            return true
          end if
        End If
      End if
    Endif
  End While
End Sub

Sub SetSpringboardVideoScreenContent(profile, springBoardScreen, video)
  springBoardScreen.ClearButtons()
  If ContainsRelevantBookmark(video) Then
    springBoardScreen.AddButton(0, "Resume from " + FormatTime(video.bookmarkPosition))
    springBoardScreen.AddButton(1, "Watch From Beginning")
  Else
    springBoardScreen.AddButton(1, "Watch")
  End If
  
  If video.favorite <> invalid and video.favorite then
    springBoardScreen.AddButton(2, "Remove from favorites")
  else 
    springBoardScreen.AddButton(3, "Add to favorites")
  end If
  
  If HasPermission(profile, "DELETE") Then
    springBoardScreen.AddButton(5, "Delete")
  End If

  springBoardScreen.SetContent(video)
End Sub

Function ShowDeleteConfirmationDialog() As Boolean
  port = CreateObject("roMessagePort")
  dialog = CreateObject("roMessageDialog")
  dialog.SetMessagePort(port)
  dialog.SetTitle("Are you sure that you want to delete?")
  ' dialog.SetText("Are you sure that you want to delete?")

  dialog.AddButton(1, "No")
  dialog.AddButton(2, "Yes")
  dialog.EnableBackButton(true)
  dialog.Show()
  While True
    msg = wait(0, dialog.GetMessagePort())
    If type(msg) = "roMessageDialogEvent"
      If msg.isScreenClosed() Then
        Return false
      Elseif msg.isButtonPressed()
        if msg.GetIndex() = 1
          Return false
        elseif msg.GetIndex() = 2
          Return true
        end if
      end if
    end if
  end while
End Function
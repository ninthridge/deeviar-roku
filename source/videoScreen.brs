Sub PlayVideo(profile, video, start) as Boolean
  videoScreen = CreateObject("roVideoScreen")
  port = CreateObject("roMessagePort")
  videoScreen.SetMessagePort(port)

  videoScreen.SetPositionNotificationPeriod(1)
  videoScreen.Show()

  video.PlayStart = start

  videoScreen.SetContent(video)
  
  currentPosition = start

  lastBookmarkDateAsSeconds = CreateObject("roDateTime").AsSeconds()
  While True
    msg = wait(0, port)
    if type(msg) = "roVideoScreenEvent" then
      if msg.isScreenClosed() then
        return IsWatched(currentPosition, video.length)
      else if msg.isStreamStarted() then
        print msg.GetInfo()
      else if msg.isFormatDetected() then
        print msg.GetInfo()
      else if msg.isPlaybackPosition() then
        currentPosition = msg.GetIndex()
        if currentPosition mod 15 = 0 and CreateObject("roDateTime").AsSeconds() - lastBookmarkDateAsSeconds > 2 then
          lastBookmarkDateAsSeconds = CreateObject("roDateTime").AsSeconds()
          v = Bookmark(profile.token, video.id, currentPosition)
          if v <> invalid then
            video.bookmarkPosition = v.bookmarkPosition
            video.bookmarkDate = v.bookmarkDate
            video.watched = v.watched
          end if
        end if
      else if msg.isRequestFailed()
        print "play failed at "; currentPosition; ": "; msg.GetIndex(); " - "; msg.GetMessage()
        print msg.GetInfo()
      endif
    end if
  End While
End Sub
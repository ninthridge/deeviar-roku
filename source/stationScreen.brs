Sub PlayStation(profile, station, playStart)
  videoScreen = CreateObject("roVideoScreen")
  port = CreateObject("roMessagePort")
  videoScreen.SetMessagePort(port)

  videoScreen.SetPositionNotificationPeriod(1)
  videoScreen.Show()

  StartOrRefreshStream(profile.token, station.id)
  stream = GetStream(profile.token, station.id)
  if stream = invalid then
    print "Invalid stream"
    return
  end if

  station.StreamFormat = stream.StreamFormat
  station.Streams = stream.Streams
  
  if playStart = invalid then
    streamStartedDate = CreateObject("roDateTime")
    streamStartedDate.FromISO8601String(stream.started)
    serverDate = GetServerDate()
    station.PlayStart = (serverDate.AsSeconds() - streamStartedDate.AsSeconds()) + 30
  else
    station.PlayStart = playStart
  end if
  
  videoScreen.SetContent(station)

  lastRefreshDateAsSeconds = CreateObject("roDateTime").AsSeconds()
  While True
    msg = wait(30000, port)
    if type(msg) = "roVideoScreenEvent" then
      if msg.isScreenClosed() then
        station.StreamFormat = invalid
        station.Stream = invalid
        station.PlayStart = invalid
        return
      else if msg.isStreamStarted() then
        print msg.GetInfo()
      else if msg.isFormatDetected() then
        print msg.GetInfo()
      ' else if msg.isStreamSegmentInfo() then
      '   print msg.GetInfo()
      else if msg.isRequestFailed()
        print "play failed at "; currentPosition; ": "; msg.GetIndex(); " - "; msg.GetMessage()
        print msg.GetInfo()
      endif
    end if
    dateAsSeconds = CreateObject("roDateTime").AsSeconds()
    if dateAsSeconds - lastRefreshDateAsSeconds > 29 then
      StartOrRefreshStream(profile.token, station.id) ' this is to ping the server so that it doesn't kill the stream
      lastRefreshDateAsSeconds = dateAsSeconds
    end if
  End While
End Sub
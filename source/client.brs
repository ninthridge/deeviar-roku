Function GetServerDate() as Object
  request = CreateObject("roUrlTransfer")
  request.SetURL(GetBaseUrl(GetHost()) + "/api")
  response = request.GetToString()
  if response <> invalid and response <> "" then
    ' TODO: add error handling
    obj = ParseJson(response)
    date = CreateObject("roDateTime")
    date.FromISO8601String(obj.sysdate)
    return date
  end if
  return invalid
End Function

Function GetServerApiVersion(host as String) as Object
  request = CreateObject("roUrlTransfer")
  request.SetURL(GetBaseUrl(GetHost()) + "/api")
  response = request.GetToString()
  if response <> invalid and response <> "" then
    ' TODO: add error handling
    obj = ParseJson(response)
    return obj.version
  end if
  return invalid
End Function

Function GetLibraryTimestamp(token as String) as Object
  request = CreateObject("roUrlTransfer")
  request.SetURL(GetBaseUrl(GetHost()) + "/api/library/timestamp")
  request.AddHeader("token", token)
  response = request.GetToString()
  if response <> invalid and response <> "" then
    ' TODO: add error handling
    obj = ParseJson(response)
    date = CreateObject("roDateTime")
    date.FromISO8601String(obj.timestamp)
    return date
  end if
  return invalid
End Function

Function StartOrRefreshStream(token as String, stationId as String) as Object
  request = CreateObject("roUrlTransfer")
  request.SetURL(GetBaseUrl(GetHost()) + "/api/streams/stations/" + stationId)
  request.AddHeader("token", token)
  request.SetRequest("PUT")
  request.PostFromString("")
End Function

Function GetStream(token as String, stationId as String) as Object
  request = CreateObject("roUrlTransfer")
  request.SetURL(GetBaseUrl(GetHost()) + "/api/streams/stations/" + stationId)
  request.AddHeader("token", token)
  response = request.GetToString()
  if response <> invalid and response <> "" then
    stream = ParseJson(response)
    EnrichContent(stream)
    return stream
  end if
  return invalid
End Function

Function StopStream(token as String) as Object
  request = CreateObject("roUrlTransfer")
  request.SetURL(GetBaseUrl(GetHost()) + "/api/streams")
  request.AddHeader("token", token)
  request.SetRequest("DELETE")
  request.GetToString()
End Function

Function CreateTimer(token as String, airingId as String, timerType as String) as Object
  request = CreateObject("roUrlTransfer")
  request.SetURL(GetBaseUrl(GetHost()) + "/api/timers/airing/" + airingId + "/" + timerType)
  request.AddHeader("token", token)
  request.SetRequest("PUT")
  request.PostFromString("")
End Function

Function GetTimerOccurrences(token as String) as Object
  request = CreateObject("roUrlTransfer")
  request.SetURL(GetBaseUrl(GetHost()) + "/api/timers/occurrences")
  request.AddHeader("token", token)
  response = request.GetToString()
  if response <> invalid and response <> "" then
    timerOccurrences = ParseJson(response)
    return timerOccurrences
  end if
  return invalid
End Function

Function DeleteTimer(token as String, timerId as String)
  request = CreateObject("roUrlTransfer")
  request.SetURL(GetBaseUrl(GetHost()) + "/api/timers/" + timerId)
  request.AddHeader("token", token)
  request.SetRequest("DELETE")
  request.GetToString()
End Function

Function Bookmark(token as String, videoId as String, bookmarkPosition as Integer) as Object
  request = CreateObject("roUrlTransfer")
  request.SetURL(GetBaseUrl(GetHost()) + "/api/library/videos/" + videoId + "/bookmark/" + bookmarkPosition.ToStr())
  request.AddHeader("token", token)
  request.SetRequest("PUT")
  response = request.GetToString()
  if response <> invalid and response <> "" then
    video = ParseJson(response)
    EnrichContent(video)
    return video
  end if
  return invalid
End Function

Function Favorite(token as String, videoId as String) as Object
  request = CreateObject("roUrlTransfer")
  request.SetURL(GetBaseUrl(GetHost()) + "/api/library/favorites/" + videoId)
  request.AddHeader("token", token)
  request.SetRequest("PUT")
  response = request.GetToString()
  if response <> invalid and response <> "" then
    video = ParseJson(response)
    EnrichContent(video)
    return video
  end if
  return invalid
End Function

Function Unfavorite(token as String, videoId as String) as Object
  request = CreateObject("roUrlTransfer")
  request.SetURL(GetBaseUrl(GetHost()) + "/api/library/favorites/" + videoId)
  request.AddHeader("token", token)
  request.SetRequest("DELETE")
  response = request.GetToString()
  if response <> invalid and response <> "" then
    video = ParseJson(response)
    EnrichContent(video)
    return video
  end if
  return invalid
End Function

Function GetProfiles() as Object
  request = CreateObject("roUrlTransfer")
  request.SetURL(GetBaseUrl(GetHost()) + "/api/profiles")
  response = request.GetToString()
  if response <> invalid and response <> "" then
    profiles = ParseJson(response)
    EnrichContents(profiles)
    return profiles
  end if
  return invalid
End Function

Function RequestToken(profileTitle as String, pin) as String
  request = CreateObject("roUrlTransfer")
  url = GetBaseUrl(GetHost()) + "/api/token?profileTitle=" + profileTitle
  if pin <> invalid then
    url = url + "&pin=" + Hash(pin)
  end if
  request.SetURL(url)
  response = request.GetToString()
  if response <> invalid and response <> "" then
    token = ParseJson(response)
    return token
  end if
  return ""
End Function

Function GetProfile(token as String) as Object
  request = CreateObject("roUrlTransfer")
  url = GetBaseUrl(GetHost()) + "/api/profile"
  request.AddHeader("token", token)
  request.SetURL(url)
  response = request.GetToString()
  if response <> invalid and response <> "" then
    profile = ParseJson(response)
    return profile
  end if
  return invalid
End Function

Function GetStations(token as String) as Object
  request = CreateObject("roUrlTransfer")
  request.SetURL(GetBaseUrl(GetHost()) + "/api/lineup/stations")
  request.AddHeader("token", token)
  response = request.GetToString()
  if response <> invalid and response <> "" then
    stations = ParseJson(response)
    EnrichContents(stations)
    return stations
  end if
  return invalid
End Function

Function GetAirings(token as String, hours as Integer, offset as Integer) as Object
  request = CreateObject("roUrlTransfer")
  url = GetBaseUrl(GetHost()) + "/api/lineup/airings?hours=" + hours.ToStr() + "&offset=" + offset.ToStr()
  request.SetURL(url)
  request.AddHeader("token", token)
  response = request.GetToString()
  if response <> invalid and response <> "" then
    airings = ParseJson(response)
    return airings
  end if
  return invalid
End Function

Function GetCategories(token as String) as Object
  request = CreateObject("roUrlTransfer")
  request.SetURL(GetBaseUrl(GetHost()) + "/api/library/categories")
  request.AddHeader("token", token)
  response = request.GetToString()
  if response <> invalid and response <> "" then
    categories = ParseJson(response)
    return categories
  end if
  return invalid
End Function

Function GetLibrary(token as String) as Object
  request = CreateObject("roUrlTransfer")
  request.SetURL(GetBaseUrl(GetHost()) + "/api/library")
  request.AddHeader("token", token)
  response = request.GetToString()
  if response <> invalid and response <> "" then
    library = ParseJson(response)
    For Each category In library
      EnrichContents(library[category])
    End For
    return library
  end if
  return invalid
End Function

Function DeleteVideo(token as String, videoId as String) as Object
  request = CreateObject("roUrlTransfer")
  request.SetURL(GetBaseUrl(GetHost()) + "/api/library/videos/" + videoId)
  request.AddHeader("token", token)
  request.SetRequest("DELETE")
  request.GetToString()
End Function

Function EnrichContents(contents)
  if contents <> invalid then
    For Each content In contents
      EnrichContent(content)
    End For
  end if
End Function

Function EnrichContent(content)
  if content <> invalid then
    If content.shortDescriptionLine1 = invalid then
      If content.shortDescrption <> invalid then
        content.shortDescriptionLine1 = content.shortDescription
      else if content.title <> invalid then
        content.shortDescriptionLine1 = content.title
      End if
    end if
    
    urlTransfer = CreateObject("roUrlTransfer")
    if content.uri <> invalid then
      content.url = toUrl(content.uri, urlTransfer)
    end if
    if content.hdPosterUri <> invalid then
      content.hdPosterUrl = toUrl(content.hdPosterUri, urlTransfer)
    end if
    if content.sdPosterUri <> invalid then
      content.sdPosterUrl = toUrl(content.sdPosterUri, urlTransfer)
    end if
    if content.hdBifUri <> invalid then
      content.hdBifUrl = toUrl(content.hdBifUri, urlTransfer)
    end if
    if content.sdBifUri <> invalid then
      content.sdBifUrl = toUrl(content.sdBifUri, urlTransfer)
    end if
    
    If content.streams <> invalid and content.streams.Count() > 0 Then
      For Each stream in content.streams
        stream.url = toUrl(stream.uri, urlTransfer)
      end For
    End If
    
    If content.subtitleTracks <> invalid and content.subtitleTracks.Count() > 0 Then
      For Each subtitleTrack in content.subtitleTracks
        subtitleTrack.trackName = toUrl(subtitleTrack.uri, urlTransfer)
      end For
    End If

    If content.episodes <> invalid Then
      EnrichContents(content.episodes)

      newestReleased = invalid
      for each episode in content.episodes 
        if newestReleased = invalid then
          newestReleased = episode.released
        else
          if episode.released <> invalid and episode.released > newestReleased then
            newestReleased = episode.released
          end if
        end if
      end for
      if newestReleased <> invalid then
        releaseDate = CreateObject("roDateTime")
        releaseDate.FromISO8601String(newestReleased)
        content.releaseDate = releaseDate.AsDateString("short-date")
      end if
    else
      If content.released <> invalid then
        releaseDate = CreateObject("roDateTime")
        releaseDate.FromISO8601String(content.released)
        content.releaseDate = releaseDate.AsDateString("short-date")
      end if
    End If
  end if
End Function

Function toUrl(uri as String, urlTransfer) as String
  url = GetBaseUrl(GetHost())
  for each s in uri.Tokenize("/")
    url = url + "/" + urlTransfer.Escape(s)
  end for
  
  return url
End Function

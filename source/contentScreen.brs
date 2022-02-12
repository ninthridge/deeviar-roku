Sub ShowContentScreen(profile, showStations)
  contentScreen = CreateObject("roGridScreen")
  port = CreateObject("roMessagePort")
  contentScreen.SetMessagePort(port)
  
  ' contentScreen.SetGridStyle("mixed-aspect-ratio")
  contentScreen.SetGridStyle("mixed-aspect-ratio")
  contentScreen.SetDisplayMode("scale-to-fit")
  contentScreen.SetBreadcrumbEnabled(true)
  contentScreen.SetCounterVisible(true)
  contentScreen.SetDescriptionVisible(true)  
  contentScreen.Show()

  stations = []
  if showStations then
    stations = GetStations(profile.token)
  end if
  library = GetLibrary(profile.token)
  categories = GetCategories(profile.token)
  libraryTimestamp = GetLibraryTimestamp(profile.token)
  
  contents = InitializeContentScreen(profile, contentScreen, stations, library, categories)
  if contents.Count() = 0 then
    ShowMessageDialog("No content available")
    return
  end if
  
  if contents.Count() > 0 and contents[0].Count() > 0 then
    contentScreen.SetFocusedListItem(0, 0)
  end if

  date = CreateObject("roDateTime")
  lastLibraryCheckDate = date
  serverDate = GetServerDate()

  while true
    libraryRefresh = false
    msg = wait(250, port)
    if type(msg) = "roGridScreenEvent" then
      if msg.isScreenClosed() then
        return
      else if msg.isListItemSelected()
        content = contents[msg.GetIndex()][msg.GetData()]
        if content.type = "Station" then
          ShowSpringboardStationScreen(profile, content)
        else if content.type = "Series" then
          libraryRefresh = ShowSpringboardSeriesScreen(profile, content, invalid)
        else if content.type = "Episode" then
          libraryRefresh = ShowSpringboardSeriesScreen(profile, FindSeries(library, content), content)
        else
          libraryRefresh = ShowSpringboardVideoScreen(profile, content)
        end if
      end if
      'have to set the description visible after each key press on mixed-aspect-ratio 
      contentScreen.SetDescriptionVisible(true)  
    end if

    date = CreateObject("roDateTime")
    if date.AsSeconds() - lastLibraryCheckDate.AsSeconds() >= 60 then
      currentLibraryTimestamp = GetLibraryTimestamp(profile.token)
      
      if currentLibraryTimestamp <> invalid and (library = invalid or libraryTimestamp = invalid or currentLibraryTimestamp.AsSeconds() > libraryTimestamp.AsSeconds()) then
        libraryRefresh = true
        libraryTimestamp = currentLibraryTimestamp
      end if
      lastLibraryCheckDate = date
    end if

    if libraryRefresh then
      if showStations then
        stations = GetStations(profile.token)
      end if
      library = GetLibrary(profile.token)
      categories = GetCategories(profile.token)
      contents = InitializeContentScreen(profile, contentScreen, stations, library, categories)

      if contents.Count() = 0 then
        ShowMessageDialog("No content available")
        return
      end if

      'TODO: error handling for GetServerDate()
      serverDate = GetServerDate()
    end if
  end while
End Sub

Sub InitializeContentScreen(profile, contentScreen, stations, library, categories) as Object
  rowTitles = CreateObject("roArray", 0, true)
  posterStyles = CreateObject("roArray", 0, true)
  contents = CreateObject("roArray", 0, true)
  
  index = 0
  If stations <> Invalid and stations.Count() > 0 Then
    rowTitles.Push("Stations")
    posterStyles.Push("square")
    contents[index] = stations
    index = index + 1
  End If

  contentFilter = 0
  while contentFilter < 4
    For Each category in categories
      contentList = library[category]
      if contentFilter = 1 then
        contentList = FindRecentlyAdded(contentList)
      else if contentFilter = 2 then
        contentList = FindUnwatched(contentList)
      else if contentFilter = 3 then
        contentList = FindFavorites(contentList)
      end if
    
      if contentList <> invalid and contentList.Count() > 0 then
        c = category
        if category = "Series" then
          c = "Episodes"
        end if

        if contentFilter = 0 then
          rowTitles.Push(category)
        else if contentFilter = 1 then
          rowTitles.Push("Recently Added " + c)
        else if contentFilter = 2 then
          rowTitles.Push("Unwatched " + c)
        else
          rowTitles.Push("Favorite " + c)
        end if
      
        if category = "Movies" or (category = "Series" and contentFilter = 0) then
          posterStyles.Push("portrait")
        else
          posterStyles.Push("landscape")
        end if
      
        contents[index] = contentList
      
        index = index + 1
      End If
    End For
    contentFilter = contentFilter + 1
  end while
  
  contentScreen.SetupLists(rowTitles.Count())
  contentScreen.SetListNames(rowTitles)
  contentScreen.SetListPosterStyles(posterStyles)
  
  index = 0
  for each contentList in contents
    contentScreen.SetContentList(index, contentList)
    index = index + 1
  end for
  
  return contents
End Sub

Sub FindUnwatched(contentList) as Object
  unwatched = CreateObject("roArray", 0, true)

  for each content in contentList
    if content.type = "Series" then
      for each episode in content.episodes
        if episode.watched = invalid or episode.watched = false then
          TimestampList(unwatched, episode, 50)
        end if
      end for
    else
      if content.watched = invalid or content.watched = false then
        TimestampList(unwatched, content, 50)
      end if
    end if
  end for
  
  return unwatched
End Sub

Sub FindRecentlyAdded(contentList) as Object
  recentlyAdded = CreateObject("roArray", 0, true)

  for each content in contentList
    if content.type = "Series" then
      for each episode in content.episodes
        TimestampList(recentlyAdded, episode, 10)
      end for
    else
      TimestampList(recentlyAdded, content, 10)
    end if
  end for

  return recentlyAdded
End Sub

Sub FindFavorites(contentList) as Object
  favorites = CreateObject("roArray", 0, true)

  for each content in contentList
    if content.type = "Series" then
      for each episode in content.episodes
        if episode.favorite <> invalid and episode.favorite = true then
          TimestampList(favorites, episode, 100)
        end if
      end for
    else
      if content.favorite <> invalid and content.favorite = true then
        TimestampList(favorites, content, 100)
      end if
    end if
  end for
  
  return favorites
End Sub

Sub TimestampList(list, video, size)
  v = video

  if v.timestamp <> invalid then
    i = 0
    while i < list.Count()
      if v.timestamp > list[i].timestamp then
        tmp = list[i]
        list[i] = v
        v = tmp
      end if
      i = i+1
    end while

    if list.Count() < size then
      list.Push(v)
    end if
  end if
End Sub

Function FindSeries(library, episode) as Object
  for each series in library.series
    if series.id = episode.seriesId then
      return series
    end if
  end for
End Function

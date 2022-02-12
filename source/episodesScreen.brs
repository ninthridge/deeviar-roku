Sub ShowEpisodesScreen(profile, series, currentEpisode) as Object
  episodesScreen = CreateObject("roListScreen")
  port = CreateObject("roMessagePort")
  episodesScreen.SetMessagePort(port)

  episodesScreen.Show()

  items = CreateObject("roArray", 0, true)
  for each episode in series.episodes
    item = CreateObject("roAssociativeArray")
    prefix = "  "
    if episode.watched <> invalid and episode.watched then
      prefix = Chr(215)
    else if ContainsRelevantBookmark(episode)
      prefix = Chr(187)
    end if
    
    item.title = prefix
    item.shortDescriptionLine1 = episode.title
    item.shortDescriptionLine2 = episode.releaseDate
    item.hdposterurl = episode.hdposterurl
    item.sdposterurl = episode.sdposterurl
    
    if episode.season <> invalid and episode.episode <> invalid then
      item.title = item.title + "  S" + episode.season.ToStr() + ": E" + episode.episode.ToStr()
      if episode.releaseDate <> invalid then
        item.title = item.title + " - " + episode.releaseDate
      end if
    elseif episode.releaseDate <> invalid then
      item.title = item.title + "  " + episode.releaseDate
    else
      item.title = item.title + "  " + episode.title
    end if
    
    items.Push(item)
  end for

  episodesScreen.setContent(items)

  index = 0
  for each episode in series.episodes
    if currentEpisode.id = episode.id then
      episodesScreen.SetFocusedListItem(index)
    end if
    index = index + 1
  end for

  While True
    msg = wait(0, port)
    if type(msg) = "roListScreenEvent" then
      If msg.isScreenClosed() Then
        Return invalid
      ElseIf msg.isListItemSelected()
        return series.episodes.GetEntry(msg.GetIndex())
      End If
    End If
  End While
End Sub


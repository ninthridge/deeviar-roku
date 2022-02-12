Sub ShowSpringboardSeriesScreen(profile, series, episode) as Boolean
  springBoardScreen = CreateObject("roSpringboardScreen")
  port = CreateObject("roMessagePort")
  springBoardScreen.SetMessagePort(port)

  springBoardScreen.SetPosterStyle("rounded-rect-16x9-generic")
  
  springBoardScreen.SetStaticRatingEnabled(False)

  springBoardScreen.Show()

  if episode = invalid then
    episode = FindBestEpisode(series)
  end if

  SetSpringboardSeriesScreenContent(profile, springBoardScreen, series, episode)

  nextEpisode = invalid
  nextEpisodeStartDateSeconds = invalid

  refresh = false

  While True
    msg = wait(1000, port)
    if type(msg) = "roSpringboardScreenEvent" then
      If msg.isScreenClosed() Then
        Return refresh
      Elseif msg.isButtonPressed()
        If msg.GetIndex() = 0 then
          nextEpisode = invalid
          nextEpisodeStartDateInSeconds = invalid
          springBoardScreen.SetBreadcrumbEnabled(false)
          watched = PlayVideo(profile, episode, episode.bookmarkPosition)
          if watched then
            nextEpisode = FindNextEpisode(series, episode)
            if nextEpisode <> invalid then
              date = CreateObject("roDateTime")
              nextEpisodeStartDateSeconds = date.AsSeconds() + 10
              springBoardScreen.SetBreadcrumbText("Next episode starts in ", "10")
              springBoardScreen.SetBreadcrumbEnabled(true)
            end if
          end if
          SetSpringboardSeriesScreenContent(profile, springBoardScreen, series, episode)
          refresh = true
        Elseif msg.GetIndex() = 1 then
          nextEpisode = invalid
          nextEpisodeStartDateInSeconds = invalid
          springBoardScreen.SetBreadcrumbEnabled(false)
          watched = PlayVideo(profile, episode, 0)
          if watched then
            nextEpisode = FindNextEpisode(series, episode)
            if nextEpisode <> invalid then
              date = CreateObject("roDateTime")
              nextEpisodeStartDateSeconds = date.AsSeconds() + 10
              springBoardScreen.SetBreadcrumbText("Next episode starts in ", "10")
              springBoardScreen.SetBreadcrumbEnabled(true)
            end if
          end if
          SetSpringboardSeriesScreenContent(profile, springBoardScreen, series, episode)
          refresh = true
        Elseif msg.GetIndex() = 2 then
          Unfavorite(profile.token, episode.id)
          episode.favorite = false
          SetSpringboardSeriesScreenContent(profile, springBoardScreen, series, episode)
          refresh = true
        Elseif msg.GetIndex() = 3 then
          Favorite(profile.token, episode.id)
          episode.favorite = true
          SetSpringboardSeriesScreenContent(profile, springBoardScreen, series, episode)
          refresh = true
        Elseif msg.GetIndex() = 4 then
          ' More Episodes
          nextEpisode = invalid
          nextEpisodeStartDateInSeconds = invalid
          springBoardScreen.SetBreadcrumbEnabled(false)
          e = ShowEpisodesScreen(profile, series, episode)
          if e <> invalid then
            episode = e
            SetSpringboardSeriesScreenContent(profile, springBoardScreen, series, episode)
          end if
        Elseif msg.GetIndex() = 5 then
          if ShowDeleteConfirmationDialog() then
            DeleteVideo(profile.token, episode.id)
            episodeIndex = FindEpisodeIndex(series, episode.id)
            if episodeIndex > -1 then
              series.episodes.Delete(episodeIndex)
            end if
            
            if series.episodes.Count() > 0 then
              
              if episodeIndex < series.episodes.Count() then
                episode = GetEpisode(series, episodeIndex)
              else
                episode = GetEpisode(series, series.episodes.Count()-1)
              end if
              SetSpringboardSeriesScreenContent(profile, springBoardScreen, series, episode)
            else
              return true
            end if
            refresh = true
          end if
        End If
      Endif
    end if

    if nextEpisode <> invalid then
      date = CreateObject("roDateTime")
      if date.AsSeconds() >= nextEpisodeStartDateSeconds then
        episode = nextEpisode
        nextEpisode = invalid
        nextEpisodeStartDateInSeconds = invalid
        springBoardScreen.SetBreadcrumbEnabled(false)
        watched = PlayVideo(profile, episode, 0)
        if watched then
          nextEpisode = FindNextEpisode(series, episode)
          if nextEpisode <> invalid then
            date = CreateObject("roDateTime")
            nextEpisodeStartDateSeconds = date.AsSeconds() + 10
            springBoardScreen.SetBreadcrumbText("Next episode starts in ", "10")
            springBoardScreen.SetBreadcrumbEnabled(true)
          end if
        end if
        SetSpringboardSeriesScreenContent(profile, springBoardScreen, series, episode)
      else
        seconds = nextEpisodeStartDateSeconds - date.AsSeconds()
        springBoardScreen.SetBreadcrumbText("Next episode starts in ", seconds.ToStr())
      end if
    end if
  End While
End Sub

Sub FindNextEpisode(series, episode) as Object
  triggered = false
  for each e in series.episodes
    if triggered = true then
      return e
    else if episode.id = e.id then
      triggered = true
    end if
  end for
  return invalid
End Sub

Sub FindBestEpisode(series) as Object
  video = invalid
  for each episode in series.episodes
    if video = invalid then
      video = episode
    Else If video.watched <> invalid and video.watched Then
      If episode.watched = invalid or episode.watched = false Then
      	video = episode
      End If
    Else If ContainsRelevantBookmark(video) Then
      If ContainsRelevantBookmark(episode) and episode.bookmarkDate > video.bookmarkDate Then
        video = episode
      End If
    Else If ContainsRelevantBookmark(episode) Then
      video = episode
    end if
  end for
  return video
End Sub

Sub SetSpringboardSeriesScreenContent(profile, springBoardScreen, series, video)
  springBoardScreen.ClearButtons()
  If ContainsRelevantBookmark(video) Then
    springBoardScreen.AddButton(0, "Resume From " + FormatTime(video.bookmarkPosition))
    springBoardScreen.AddButton(1, "Watch From Beginning")
  Else
    springBoardScreen.AddButton(1, "Watch")
  End If

  If video.favorite <> invalid and video.favorite then
    springBoardScreen.AddButton(2, "Remove from favorites")
  else 
    springBoardScreen.AddButton(3, "Add to favorites")
  end If

  If series.episodes.Count() > 1 Then
    springBoardScreen.AddButton(4, "More Episodes")
  End If

  If HasPermission(profile, "DELETE") Then
    springBoardScreen.AddButton(5, "Delete")
  End If

  springBoardScreen.SetContent(video)
End Sub

Function FindEpisodeIndex(series, episodeId) as integer
  index = -1
  for each episode in series.episodes
    index = index + 1
    if episode.id = episodeId then
      return index
    end if
  end for
  return index
end Function

Function GetEpisode(series, episodeIndex) as Object
  index = -1
  for each episode in series.episodes
    index = index + 1
    if index = episodeIndex then
      return episode
    end if
  end for
  return invalid
end Function
Sub HasPermission(profile, permission) as Boolean
  If profile.permissions <> invalid Then
    For Each p In profile.permissions
      If p = permission then
        return true
      End If
    End For
  End If
  return false
End Sub

Sub FormatTime(timeInSeconds as Integer) as String
  seconds = timeInSeconds mod 60
  minutes = ((timeInSeconds - seconds) / 60) mod 60
  hours = (timeInSeconds - (seconds + (minutes * 60))) / 3600

  formattedTime = seconds.ToStr()
  If seconds < 10 Then
    formattedTime = "0" + formattedTime
  End If

  formattedTime = Str(minutes) + ":" + formattedTime

  If hours > 0 Then
    If minutes < 10 Then
      formattedTime = "0" + formattedTime
    End If
    formattedTime = Str(hours) + ":" + formattedTime
  End If

  return formattedTime
End Sub

Sub ContainsRelevantBookmark(video) as Boolean
  return video.bookmarkPosition <> invalid and video.bookmarkPosition >= 180 and IsVideoWatched(video) = false
End Sub

Sub IsVideoWatched(video) as Boolean
  if video.length <> invalid and video.length > 0 then
    return IsWatched(video.bookmarkPosition, video.length)
  end if
  return false
End Sub

Sub IsWatched(position, length) as Boolean
  return position / length >= .92
End Sub

Function GetBaseUrl(host as String)
  if host.Instr(0, ":") = -1 then
    host = host + ":7111"
  end if
  host = "http://" + host
  return host
End Function

Function Hash(str as String)
  ba = CreateObject("roByteArray")
  ba.FromAsciiString(str)
  digest = CreateObject("roEVPDigest")
  digest.Setup("sha256")
  return digest.Process(ba)
End Function
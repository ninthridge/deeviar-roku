Sub GetHost() as String
  configRegistrySection = CreateObject("roRegistrySection", "Config")
  if configRegistrySection.Exists("Host") then
    return configRegistrySection.Read("Host")
  end if
  return ""
End Sub

Sub SaveHost(host As String)
  configRegistrySection = CreateObject("roRegistrySection", "Config")
  configRegistrySection.Write("Host", host)
  configRegistrySection.Flush()
End Sub

Sub GetContentFilter(profileTitle as String) as integer
  profileRegistrySection = CreateObject("roRegistrySection", profileTitle)
  if profileRegistrySection.Exists("ContentFilter") then
    return profileRegistrySection.Read("ContentFilter").ToInt()
  end if
  return 1
End Sub

Sub SaveContentFilter(profileTitle as String, contentFilter as integer)
  profileRegistrySection = CreateObject("roRegistrySection", profileTitle)
  profileRegistrySection.Write("ContentFilter", contentFilter.ToStr())
  profileRegistrySection.Flush()
End Sub
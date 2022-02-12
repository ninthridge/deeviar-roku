Sub ShowConfigScreen() as Boolean
  configScreen = CreateObject("roKeyboardScreen")
  port = CreateObject("roMessagePort")
  configScreen.SetMessagePort(port)

  host = GetHost()

  configScreen.SetTitle("Host")
  configScreen.SetDisplayText("Please enter the deeviar server name or ip address.")
  configScreen.AddButton(1, "OK")
  configScreen.AddButton(2, "Cancel")
  
  if host <> invalid then
    configScreen.SetText(host)
  end if

  configScreen.Show()

  while true
    msg = wait(0, configScreen.GetMessagePort())
    if type(msg) = "roKeyboardScreenEvent" then
      if msg.isScreenClosed() then
        return false
      else if msg.isButtonPressed() then
        if msg.GetIndex() = 1 then
          host = configScreen.GetText()
          if host = invalid or host.Trim() = "" then
            ShowMessageDialog("Invalid Host")
          else
            host = host.Trim()
            SaveHost(host)
            return true
          end if
        end if
        if msg.GetIndex() = 2 then
          return false
        end if
      end if
    end if
  end while
End Sub
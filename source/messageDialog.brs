Function ShowMessageDialog(msg) As Void
  port = CreateObject("roMessagePort")
  dialog = CreateObject("roMessageDialog")
  dialog.SetMessagePort(port)
  dialog.SetTitle("")
  dialog.SetText(msg)
 
  dialog.AddButton(1, "OK")
  dialog.EnableBackButton(true)
  dialog.Show()
  While True
    dlgMsg = wait(0, dialog.GetMessagePort())
    If type(dlgMsg) = "roMessageDialogEvent" then
      if dlgMsg.isButtonPressed() then
        if dlgMsg.GetIndex() = 1 then
          dialog.Close()
          return
        end if
      else if dlgMsg.isScreenClosed() then
        return
      end if
    end if
  end while
End Function
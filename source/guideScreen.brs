Sub ShowGuideScreen(profile)
  canvas = CreateObject("roImageCanvas")
  port = CreateObject("roMessagePort")
  canvas.SetMessagePort(port)

  canvas.SetRequireAllImagesToDraw(true)

  font_registry = CreateObject("roFontRegistry")
  font = font_registry.GetDefaultFont(25, false, false)
  
  deviceInfo = CreateObject("roDeviceInfo")
  displaySize = deviceInfo.GetDisplaySize()

  screenWidth = displaySize.w
  screenHeight = displaySize.h

  screenBorder = 50
  cellHeight = 47
  cellBorder = 3
  cellInset = 5

  ' TODO: these dimensions should be dynamic based on the tv screen
  headerHeight = 88

  ' detailsHeight = Int((displaySize.h - headerHeight - (screenBorder*2)) / 4)
  detailsHeight = 82

  visibleRows = Int((displaySize.h - headerHeight - (screenBorder * 2) - detailsHeight) / (cellHeight+cellBorder)) - 1

  visibleCols = 4
  cellWidth = Int((displaySize.w - (screenBorder * 2)) / (visibleCols + 1))

  selectedRow = 0
  selectedCol = 0

  colOffset = 0
  rowOffset = 0

  stations = GetStations(profile.token)
  airings = GetAiringsMultiArray(profile, stations, colOffset)
  timerOccurrences = GetTimerOccurrences(profile.token)
  
  date = CreateObject("roDateTime")
  localDateAsSeconds = date.AsSeconds()
  serverDateAsSeconds = GetServerDate().AsSeconds()
  lastGuideRefreshDate = date
  nextGuideRefresh = localDateAsSeconds + (1801 - (serverDateAsSeconds mod 1800))
  nextTimelineRefresh = localDateAsSeconds + (serverDateAsSeconds mod 60)
  
  paintBg(font, canvas, screenWidth, screenHeight, screenBorder, visibleCols, visibleRows, cellBorder, cellWidth, cellHeight, headerHeight, detailsHeight)
  paint(font, canvas, screenBorder, visibleCols, visibleRows, cellBorder, cellInset, cellWidth, cellHeight, headerHeight, colOffset, rowOffset, stations, airings, timerOccurrences, serverDateAsSeconds)
  paintHighlighted(canvas, screenBorder, visibleCols, visibleRows, cellBorder, cellInset, cellWidth, cellHeight, headerHeight, detailsHeight, colOffset, rowOffset, selectedCol, selectedRow, stations, airings, serverDateAsSeconds)
  paintTimeline(canvas, screenBorder, visibleCols, visibleRows, cellBorder, cellInset, cellWidth, cellHeight, headerHeight, colOffset, serverDateAsSeconds)
  
  canvas.Show()

  While True
    forceRefresh = false
    forceTimelineRefresh = false
    msg = wait(1000, port)
    if type(msg) = "roImageCanvasEvent" then
      if msg.isScreenClosed() then
        return
      else if msg.isRemoteKeyPressed() then
        i = msg.GetIndex()
        if i = 0 then
          ' Back
          ' return
        else if i = 2 then
          ' Up
          previousSelectedAiring = airings[selectedRow+rowOffset][selectedCol]
          
          if selectedRow > 0 then
            selectedRow = selectedRow - 1
          else if rowOffset > 0 then
            rowOffset = rowOffset - 1
            paint(font, canvas, screenBorder, visibleCols, visibleRows, cellBorder, cellInset, cellWidth, cellHeight, headerHeight, colOffset, rowOffset, stations, airings, timerOccurrences, serverDateAsSeconds)
          end if
          
          if selectedCol > 0 then
            previouslySelectedAiringStartDate = CreateObject("roDateTime")
            previouslySelectedAiringStartDate.FromISO8601String(previousSelectedAiring.start)
            c = FindAiringIndex(previouslySelectedAiringStartDate, airings[selectedRow+rowOffset])
            if c >= 0 then
              selectedCol = c
            else if selectedCol >= airings[selectedRow+rowOffset].Count()-1 then
              'This should never happen
              selectedCol = airings[selectedRow+rowOffset].Count()-1
            end if
          end if
          
          paintHighlighted(canvas, screenBorder, visibleCols, visibleRows, cellBorder, cellInset, cellWidth, cellHeight, headerHeight, detailsHeight, colOffset, rowOffset, selectedCol, selectedRow, stations, airings, serverDateAsSeconds)
  
        else if i = 3 then
          ' Down
          previousSelectedAiring = airings[selectedRow+rowOffset][selectedCol]
          
          if selectedRow < visibleRows-1 then
            selectedRow = selectedRow + 1
          else if airings.Count() > rowOffset + visibleRows then
            rowOffset = rowOffset + 1
            paint(font, canvas, screenBorder, visibleCols, visibleRows, cellBorder, cellInset, cellWidth, cellHeight, headerHeight, colOffset, rowOffset, stations, airings, timerOccurrences, serverDateAsSeconds)
          end if
          
          if selectedCol > 0 then
            previouslySelectedAiringStartDate = CreateObject("roDateTime")
            previouslySelectedAiringStartDate.FromISO8601String(previousSelectedAiring.start)
            c = FindAiringIndex(previouslySelectedAiringStartDate, airings[selectedRow+rowOffset])
            if c >= 0 then
              selectedCol = c
            else if selectedCol >= airings[selectedRow+rowOffset].Count()-1 then
              'This should never happen
              selectedCol = airings[selectedRow+rowOffset].Count()-1
            end if
          end if
          paintHighlighted(canvas, screenBorder, visibleCols, visibleRows, cellBorder, cellInset, cellWidth, cellHeight, headerHeight, detailsHeight, colOffset, rowOffset, selectedCol, selectedRow, stations, airings, serverDateAsSeconds)
  
        else if i = 4 then
          ' Left
          if selectedCol > 0 then
            selectedCol = selectedCol - 1
            paintHighlighted(canvas, screenBorder, visibleCols, visibleRows, cellBorder, cellInset, cellWidth, cellHeight, headerHeight, detailsHeight, colOffset, rowOffset, selectedCol, selectedRow, stations, airings, serverDateAsSeconds)
          else if colOffset > 0 then
            colOffset = colOffset - 1
            selectedCol = 100
            forceRefresh = true
            if colOffset = 0 then
              forceTimelineRefresh = true
            end if
          end if
        else if i = 5 then
          ' Right
          if selectedCol < airings[selectedRow+rowOffset].Count()-1 then
            selectedCol = selectedCol + 1
            paintHighlighted(canvas, screenBorder, visibleCols, visibleRows, cellBorder, cellInset, cellWidth, cellHeight, headerHeight, detailsHeight, colOffset, rowOffset, selectedCol, selectedRow, stations, airings, serverDateAsSeconds)
          else
            nextAirings = GetAiringsMultiArray(profile, stations, colOffset+1)
            if nextAirings <> invalid and nextAirings.Count() > 0
              colOffset = colOffset + 1
              selectedCol = 0
              forceRefresh = true
              if colOffset = 1 then
                forceTimelineRefresh = true
              end if
            end if
          end if
        else if i = 6 or i = 13 then
          ' OK / Play
          station = stations[selectedRow+rowOffset]
          airing = airings[selectedRow+rowOffset][selectedCol]
          if airing <> invalid then
            forceRefresh = ShowSpringboardAiringScreen(profile, station, airing)
          else if station <> invalid then
            ShowSpringboardStationScreen(profile, station)
          end if
        else if i = 10 then
          ' Asterisk
          ShowContentScreen(profile, false)
        end if
      end if
    end if
    
    date = CreateObject("roDateTime")
    if forceRefresh or date.AsSeconds() >= nextGuideRefresh then
      localDateAsSeconds = date.AsSeconds()
      serverDateAsSeconds = GetServerDate().AsSeconds()
      lastGuideRefreshDate = date
      nextGuideRefresh = localDateAsSeconds + (1801 - (serverDateAsSeconds mod 1800))
      
      stations = GetStations(profile.token)
      timerOccurrences = GetTimerOccurrences(profile.token)
      ' TODO: use the already pulled nextAirings when this is the result of a move right event
      airings = GetAiringsMultiArray(profile, stations, colOffset)
      
      if selectedCol > airings[selectedRow+rowOffset].Count() then
        selectedCol = airings[selectedRow+rowOffset].Count()-1
      end if
      
      paint(font, canvas, screenBorder, visibleCols, visibleRows, cellBorder, cellInset, cellWidth, cellHeight, headerHeight, colOffset, rowOffset, stations, airings, timerOccurrences, serverDateAsSeconds)
      paintHighlighted(canvas, screenBorder, visibleCols, visibleRows, cellBorder, cellInset, cellWidth, cellHeight, headerHeight, detailsHeight, colOffset, rowOffset, selectedCol, selectedRow, stations, airings, serverDateAsSeconds)
    end if
    
    if date.AsSeconds() >= nextTimelineRefresh or forceTimelineRefresh then
      serverDateAsSeconds = serverDateAsSeconds + (date.AsSeconds() - localDateAsSeconds)
      localDateAsSeconds = date.AsSeconds()
      nextTimelineRefresh = localDateAsSeconds + (60 - (serverDateAsSeconds mod 60))
      paintTimeline(canvas, screenBorder, visibleCols, visibleRows, cellBorder, cellInset, cellWidth, cellHeight, headerHeight, colOffset, serverDateAsSeconds)
    end if
  End While
End Sub

Sub paintBg(font, canvas, screenWidth, screenHeight, screenBorder, visibleCols, visibleRows, cellBorder, cellWidth, cellHeight, headerHeight, detailsHeight)

  backgrounds = []

  headerBg = {}
  headerBg.url = "pkg:/images/overhang_hd.png"
  headerBg.TargetRect = {}
  headerBg.TargetRect.w = screenWidth
  headerBg.TargetRect.x = 0
  headerBg.TargetRect.h = screenBorder + headerHeight
  headerBg.TargetRect.y = 0

  guideBg = {}
  guideBg.Color = "#FF000000"
  guideBg.TargetRect = {}
  guideBg.TargetRect.w = cellBorder + ((visibleCols+1) * (cellWidth+cellBorder))
  guideBg.TargetRect.x = screenBorder
  guideBg.TargetRect.h = cellBorder + ((visibleRows+1) * (cellHeight+cellBorder))
  guideBg.TargetRect.y = screenBorder + headerHeight

  c = 0
  while c < visibleCols+1
    colHeaderBg = {}
    colHeaderBg.Color = "#FF202020"
    colHeaderBg.TargetRect = {}
    colHeaderBg.TargetRect.w = cellWidth
    colHeaderBg.TargetRect.x = screenBorder + cellBorder + (c*(cellWidth+cellBorder))
    colHeaderBg.TargetRect.h = cellHeight
    colHeaderBg.TargetRect.y = screenBorder + headerHeight + cellBorder
    backgrounds.Push(colHeaderBg)

    c = c + 1
  end while

  r = 0
  while r < visibleRows
    rowHeaderBg = {}
    rowHeaderBg.TargetRect = {}
    rowHeaderBg.TargetRect.w = cellWidth
    rowHeaderBg.TargetRect.x = screenBorder + cellBorder
    rowHeaderBg.TargetRect.h = cellHeight
    rowHeaderBg.TargetRect.y = screenBorder + headerHeight + cellBorder + ((r+1)*(cellHeight+cellBorder))
    backgrounds.Push(rowHeaderBg)

    rowBg = {}
    rowBg.Color = "#FF303030"
    rowBg.TargetRect = {}
    rowBg.TargetRect.w = ((cellWidth+cellBorder)*visibleCols) - cellBorder
    rowBg.TargetRect.x = screenBorder + cellBorder + cellWidth + cellBorder
    rowBg.TargetRect.h = cellHeight
    rowBg.TargetRect.y = screenBorder + headerHeight + cellBorder + ((r+1)*(cellHeight+cellBorder))
    backgrounds.Push(rowBg)

    r = r + 1
  end while

  logos = []
  logo = {}
  logo.url = "pkg:/images/Deeviar395X125.png"
  logo.TargetRect = {}
  logo.TargetRect.w = 395
  logo.TargetRect.x = 30
  logo.TargetRect.h = 125
  logo.TargetRect.y = 6
  logos.Push(logo)

  breadcrumbText = "Press * to access your library"
  breadcrumbTextWidth = font.GetOneLineWidth(breadcrumbText, 1280)
  

  breadcrumbs = []
  breadcrumb = {}
  breadcrumb.Text = "Press * to access your library"
  breadcrumb.TextAttrs = {Color:"#FFEFEFEF", Font:"Small", HAlign:"Right", VAlign:"Top", Direction:"LeftToRight"}
  breadcrumb.TargetRect = {}
  breadcrumb.TargetRect.w = breadcrumbTextWidth
  breadcrumb.TargetRect.x = screenWidth - breadcrumbTextWidth - screenBorder
  breadcrumb.TargetRect.h = cellHeight
  breadcrumb.TargetRect.y = screenBorder
  breadcrumbs.push(breadcrumb)
  
  canvas.SetLayer(0, {Color:"#FF363636", CompositionMode:"Source"})
  canvas.SetLayer(1, headerBg)
  canvas.SetLayer(2, guideBg)
  canvas.SetLayer(3, backgrounds)
  canvas.SetLayer(4, logos)
  canvas.SetLayer(5, breadcrumbs)
End Sub

Sub paint(font, canvas, screenBorder, visibleCols, visibleRows, cellBorder, cellInset, cellWidth, cellHeight, headerHeight, colOffset, rowOffset, stations, airings, timerOccurrences, serverDateAsSeconds)

  guideStart = serverDateAsSeconds + (colOffset * visibleCols * 1800) - (serverDateAsSeconds mod 1800)
  guideEnd = guideStart + (visibleCols * 1800)

  cells = []
  timerCells = []
  
  guideStartDate = CreateObject("roDateTime")
  guideStartDate.FromSeconds(guideStart)

  ' top left corner date cell
  cell = {}
  cell.Text = guideStartDate.AsDateString("short-month-short-weekday")
  cell.TextAttrs = {Color:"#FFEFEFEF", Font:"Small", HAlign:"Center", VAlign:"Middle", Direction:"LeftToRight"}
  cell.TargetRect = {}
  cell.TargetRect.w = cellWidth - (cellInset * 2)
  cell.TargetRect.x = screenBorder + cellBorder + cellInset
  cell.TargetRect.h = cellHeight - (cellInset * 2)
  cell.TargetRect.y = screenBorder + headerHeight + cellBorder + cellInset
  cells.Push(cell)

  ' column headers broken in 30 minute increments
  c = 0
  while c < visibleCols
    date = CreateObject("roDateTime")
    date.FromSeconds(guideStart + (c*1800))

    cell = {}
    cell.TargetRect = {}
    cell.TargetRect.w = cellWidth - (cellInset * 2)
    cell.TargetRect.x = screenBorder + cellBorder + ((c+1)*(cellWidth+cellBorder)) + cellInset
    cell.TargetRect.h = cellHeight - (cellInset * 2)
    cell.TargetRect.y = screenBorder + headerHeight + cellBorder + cellInset
    cell.Text = FormatDate(date)
    cell.TextAttrs = {Color:"#FFEFEFEF", Font:"Small", HAlign:"Left", VAlign:"Middle", Direction:"LeftToRight"}
    cells.Push(cell)

    c = c + 1
  end while

  ' row headers that contains channel numbers and callsigns
  r = 0
  while r < visibleRows
    station = stations[r+rowOffset]

    cells.Push(stationCell(screenBorder, cellBorder, cellInset, cellWidth, cellHeight, headerHeight, r, station))

    r = r + 1
  end while

  ' timerOccurrences
  r = 0
  while r < visibleRows
    station = stations[r+rowOffset]
    
    for each timer in timerOccurrences
      if timer.stationId = station.id then
      
        timerStartDate = CreateObject("roDateTime")
        timerStartDate.FromISO8601String(timer.startDate)
        timerStart = timerStartDate.AsSeconds()
        timerDuration = timer.duration
        timerEnd = timerStart + timerDuration

        if timerEnd > guideStart and timerStart < guideEnd and timerDuration > 0 then
          duration = timerDuration
          relativeStart = timerStart
          relativeEnd = timerEnd

          if guideStart > relativeStart then
            relativeStart = guideStart
            duration = duration - (guideStart - timerStart)
          end if

          if relativeEnd > guideEnd then
            relativeEnd = guideEnd
            duration = duration - (timerEnd - guideEnd)
          end if

          cell = {}
          cell.Color = "#FF600000"
          cell.TargetRect = {}
          cell.TargetRect.w = Int((duration * (cellWidth+cellBorder)) / 1800)
          cell.TargetRect.x = screenBorder + cellBorder + cellWidth + cellBorder + Int(((relativeStart - guideStart) * (cellWidth+cellBorder)) / 1800)
          cell.TargetRect.h = cellHeight
          cell.TargetRect.y = screenBorder + headerHeight + cellBorder + ((r+1)*(cellHeight+cellBorder))
          timerCells.Push(cell)
          
        end if
      end if
    end for
  
    r = r + 1
  end while

  ' airings
  r = 0
  while r < visibleRows
    c = 0
    for each airing in airings[r+rowOffset]
      cell = airingCell(screenBorder, cellBorder, cellInset, cellWidth, cellHeight, headerHeight, rowOffset, r, guideStart, guideEnd, airing)
      if cell <> invalid then
        cell.Text = trimText(font, airing.title, cell.TargetRect.w)
        cell.TextAttrs = {Color:"#FFEFEFEF", Font:"Small", HAlign:"Left", VAlign:"Middle", Direction:"LeftToRight"}
        cells.Push(cell)
      end if
      c = c + 1
    end for
    r = r + 1
  end while

  canvas.SetLayer(6, timerCells)
  canvas.SetLayer(7, cells)
  
End Sub

Sub paintHighlighted(canvas, screenBorder, visibleCols, visibleRows, cellBorder, cellInset, cellWidth, cellHeight, headerHeight, detailsHeight, colOffset, rowOffset, selectedCol, selectedRow, stations, airings, serverDateAsSeconds)
  
  highlighterColor = "#FF2EB8D4"
  ' highlighterColor = "#FF6682FF"
  
  highlighter = []
  details = []
  
  guideStart = serverDateAsSeconds + (colOffset * visibleCols * 1800) - (serverDateAsSeconds mod 1800)
  guideEnd = guideStart + (visibleCols * 1800)
  
  detailsTitle = {}
  detailsDescription = {}
  station = stations[selectedRow+rowOffset]
  airing = airings[selectedRow+rowOffset][selectedCol]
  if airing <> invalid then
    cell = airingCell(screenBorder, cellBorder, cellInset, cellWidth, cellHeight, headerHeight, rowOffset, selectedRow, guideStart, guideEnd, airing)
    detailsTitle.Text = airing.title
    detailsDescription.Text = airing.description
  else if station <> invalid then
    cell = stationCell(screenBorder, cellBorder, cellInset, cellWidth, cellHeight, headerHeight, selectedRow, station)
    detailsTitle.Text = station.title
    detailsDescription.Text = station.description
  end if
  
  if cell <> invalid then
    highlighterTop = {}
    highlighterTop.Color = highlighterColor
    highlighterTop.TargetRect = {}
    
    highlighterTop.TargetRect.w = cell.TargetRect.w + (cellInset * 2) + (cellBorder * 2)
    highlighterTop.TargetRect.x = cell.TargetRect.x - cellInset - cellBorder
    highlighterTop.TargetRect.h = cellBorder
    highlighterTop.TargetRect.y = cell.TargetRect.y - cellInset - cellBorder
    highlighter.Push(highlighterTop)

    highlighterBottom = {}
    highlighterBottom.Color = highlighterColor
    highlighterBottom.TargetRect = {}
    highlighterBottom.TargetRect.w = cell.TargetRect.w + (cellInset * 2) + (cellBorder * 2)
    highlighterBottom.TargetRect.x = cell.TargetRect.x - cellInset  - cellBorder
    highlighterBottom.TargetRect.h = cellBorder
    highlighterBottom.TargetRect.y = cell.TargetRect.y + cell.TargetRect.h + cellInset
    highlighter.Push(highlighterBottom)

    highlighterLeft = {}  
    highlighterLeft.Color = highlighterColor
    highlighterLeft.TargetRect = {}
    highlighterLeft.TargetRect.w = cellBorder
    highlighterLeft.TargetRect.x = cell.TargetRect.x - cellInset  - cellBorder
    highlighterLeft.TargetRect.h = cell.TargetRect.h + (cellInset * 2) + (cellBorder * 2)
    highlighterLeft.TargetRect.y = cell.TargetRect.y - cellInset  - cellBorder
    highlighter.Push(highlighterLeft)

    highlighterRight = {}
    highlighterRight.Color = highlighterColor
    highlighterRight.TargetRect = {}
    highlighterRight.TargetRect.w = cellBorder
    highlighterRight.TargetRect.x = cell.TargetRect.x + cell.TargetRect.w + cellInset
    highlighterRight.TargetRect.h = cell.TargetRect.h + (cellInset * 2) + (cellBorder * 2)
    highlighterRight.TargetRect.y = cell.TargetRect.y - cellInset  - cellBorder
    highlighter.Push(highlighterRight)
    
    if detailsHeight > 0 then
      detailsTitle.TextAttrs = {Color:"#FFEFEFEF", Font:"Small", HAlign:"Left", VAlign:"Middle", Direction:"LeftToRight"}
      detailsTitle.TargetRect = {}
      detailsTitle.TargetRect.w = ((cellWidth+cellBorder) * (visibleCols)) - (cellInset*2)
      detailsTitle.TargetRect.x = screenBorder + cellWidth + cellBorder + cellInset
      detailsTitle.TargetRect.h = cellHeight - (cellInset*2)
      detailsTitle.TargetRect.y = screenBorder + headerHeight + cellBorder + ((cellHeight+cellBorder) * (visibleRows+1)) + cellInset
      details.Push(detailsTitle)

      detailsDescription.TextAttrs = {Color:"#FFEFEFEF", Font:"Small", HAlign:"Left", VAlign:"Top", Direction:"LeftToRight"}
      detailsDescription.TargetRect = {}
      detailsDescription.TargetRect.w = detailsTitle.TargetRect.w
      detailsDescription.TargetRect.x = detailsTitle.TargetRect.x
      detailsDescription.TargetRect.h = detailsHeight - detailsTitle.TargetRect.h + cellBorder - (cellInset * 2)
      detailsDescription.TargetRect.y = detailsTitle.TargetRect.y + detailsTitle.TargetRect.h + cellBorder + cellInset
      details.Push(detailsDescription)
    end if
  end if

  canvas.SetLayer(8, details)
  canvas.SetLayer(9, highlighter)
End Sub

Sub paintTimeline(canvas, screenBorder, visibleCols, visibleRows, cellBorder, cellInset, cellWidth, cellHeight, headerHeight, colOffset, serverDateAsSeconds)
  guideStart = serverDateAsSeconds + (colOffset * visibleCols * 1800) - (serverDateAsSeconds mod 1800)
  timeline = {}
  if colOffset = 0 then
    timeline.Color = "#FF6682FF"
    timeline.TargetRect = {}
    timeline.TargetRect.w = 2
    timeline.TargetRect.x = Int(((serverDateAsSeconds - guideStart) * cellWidth) / 1800) + cellWidth + screenBorder
    ' timeline.TargetRect.h = (cellHeight * visibleRows) - cellBorder
    ' timeline.TargetRect.y = screenBorder + headerHeight + cellHeight
    timeline.TargetRect.h = cellHeight
    timeline.TargetRect.y = screenBorder + headerHeight + cellBorder
  end if
  canvas.SetLayer(10, timeline)
End Sub

Sub stationCell(screenBorder, cellBorder, cellInset, cellWidth, cellHeight, headerHeight, row, station) as Object
  cell = {}
  cell.TargetRect = {}
  cell.TargetRect.w = cellWidth - (cellInset * 2)
  cell.TargetRect.x = screenBorder + cellBorder + cellInset + cellBorder
  cell.TargetRect.h = cellHeight - (cellInset * 2)
  cell.TargetRect.y = screenBorder + headerHeight + cellBorder + ((row+1)*(cellHeight+cellBorder)) + cellInset
  cell.Text = station.channel + " " + station.callSign
  cell.TextAttrs = {Color:"#FFEFEFEF", Font:"Small", HAlign:"Left", VAlign:"Middle", Direction:"LeftToRight"}
  return cell
End Sub

Sub airingCell(screenBorder, cellBorder, cellInset, cellWidth, cellHeight, headerHeight, rowOffset, row, guideStart, guideEnd, airing) as Object
  
  airingStartDate = CreateObject("roDateTime")
  airingStartDate.FromISO8601String(airing.start)
  airingStart = airingStartDate.AsSeconds()
  airingDuration = airing.duration
  airingEnd = airingStart + airingDuration
  
  duration = airingDuration
  relativeStart = airingStart
  relativeEnd = airingEnd

  if guideStart > relativeStart then
    relativeStart = guideStart
    duration = duration - (guideStart - airingStart)
  end if

  if relativeEnd > guideEnd then
    relativeEnd = guideEnd
    duration = duration - (airingEnd - guideEnd)
  end if

  cell = invalid
  if duration > 0 then
    cell = {}
    cell.TargetRect = {}
    cell.TargetRect.w = Int((duration * (cellWidth+cellBorder)) / 1800) - (cellInset * 2)
    cell.TargetRect.x = screenBorder + cellBorder + cellWidth + cellBorder + Int(((relativeStart - guideStart) * (cellWidth+cellBorder)) / 1800) + cellInset
    cell.TargetRect.h = cellHeight - (cellInset * 2)
    cell.TargetRect.y = screenBorder + headerHeight + cellBorder + ((row+1)*(cellHeight+cellBorder)) + cellInset
  end if
  return cell
End Sub

Sub GetAiringsMultiArray(profile, stations, offset) as Object
  hours = 2
  airingsMultiArray = []
  airings = GetAirings(profile.token, hours, offset)
  if stations <> invalid then
    for each station in stations
      stationAiringsArray = []
      if airings <> invalid and airings[station.id] <> invalid then
        for each airing in airings[station.id]
          airing.hdPosterUrl = station.hdPosterUrl
          airing.sdPosterUrl = station.hdPosterUrl
          stationAiringsArray.Push(airing)
        end for
      end if
      airingsMultiArray.Push(stationAiringsArray)
    end for
  end if
  return airingsMultiArray
End Sub

Sub FindAiringIndex(date, airings) as Integer
  c = 0
  while c < airings.Count()
    airing = airings[c]
            
    airingStartDate = CreateObject("roDateTime")
    airingStartDate.FromISO8601String(airing.start)
    airingStart = airingStartDate.AsSeconds()
    airingDuration = airing.duration
    airingEnd = airingStart + airingDuration
            
    if airingStart <= date.AsSeconds() and airingEnd > date.AsSeconds() then 
      return c
    end if
    c = c + 1
  end while
  return -1
End Sub

Sub trimText(font, text, width) as Object
  index = text.Len()
  textWidth = font.GetOneLineWidth(text, 1280)
  while textWidth > width and index > 0
    index = index - 1
    textWidth = font.GetOneLineWidth(text.Left(index) + "...", 1280)
  end while

  if index = text.Len() then
    return text
  else if index > 0 then
    return text.Left(index) + "..."
  else
    return ""
  end if
End Sub

Sub FormatDate(date as object) as String
  hours = date.GetHours()
  period = "AM"
  if hours = 0 then
    hours = 12
  else if hours > 12 then
    hours = hours - 12
    period = "PM"
  end if
  minutes = date.GetMinutes()
  minutesStr = minutes.ToStr()
  if minutes < 10 then
    minutesStr = "0" + minutesStr
  end if
  s = hours.ToStr() + ":" + minutesStr + " " + period
  return s
End Sub
--AudioSuite-like Script. Renders the selected plugin to the selected media item.
--Written for Reaper 5.1 with Lua
--v1.1 12/22/2015
--Added PreventUIRefresh
--Written by Tim Chimes
--http://chimesaudio.com
--


function debug(message) --logging
  --reaper.ShowConsoleMsg(tostring(message))
end

function getSelectedMedia() --Get value of Media Item that is selected
  selitem = 0
  MediaItem = reaper.GetSelectedMediaItem(0, selitem)
  debug (MediaItem)
  return MediaItem
end

function countSelected() --Makes sure there is only 1 MediaItem selected
  if reaper.CountSelectedMediaItems(0) == 1 then
    debug("Media Item is Selected! \n")
    return true
    else 
      debug("Must Have only ONE Media Item Selected")
      return false
  end
end

function checkSelectedFX() --Determines if a TrackFX is selected, and which FX is selected
  retval = 0
  tracknumberOut = 0
  itemnumberOut = 0
  fxnumberOut = 0
  window = false
  
  retval, tracknumberOut, itemnumberOut, fxnumberOut = reaper.GetFocusedFX()
  debug ("\n"..retval..tracknumberOut..itemnumberOut..fxnumberOut)
  
  track = tracknumberOut - 1
  
  if track == -1 then
    track = 0
  else
  end
  
  mtrack = reaper.GetTrack(0, track)
  
  window = reaper.TrackFX_GetOpen(mtrack, fxnumberOut)
  
  return retval, tracknumberOut, itemnumberOut, fxnumberOut, window
end

function getFXname(trackNumber, fxNumber) --Get FX name
  track = trackNumber - 1
  FX = fxNumber
  FXname = ""
  
  mTrack = reaper.GetTrack (0, track)
    
  retvalfx, FXname = reaper.TrackFX_GetFXName(mTrack, FX, FXname)
    
  return FXname, mTrack
end

function bypassUnfocusedFX(FXmediaTrack, fxnumber_Out, render)--bypass and unbypass FX on FXtrack
  FXtrack = FXmediaTrack
  FXnumber = fxnumber_Out

  FXtotal = reaper.TrackFX_GetCount(FXtrack)
  FXtotal = FXtotal - 1
  
  if render == false then
    for i = 0, FXtotal do
      if i == FXnumber then
        reaper.TrackFX_SetEnabled(FXtrack, i, true)
      else reaper.TrackFX_SetEnabled(FXtrack, i, false)
      i = i + 1
      end
    end
  else
    for i = 0, FXtotal do
      reaper.TrackFX_SetEnabled(FXtrack, i, true)
      i = i + 1
    
    end
  end
  
  return
end

function getLoopSelection()--Checks to see if there is a loop selection
  startOut = 0
  endOut = 0
  isSet = false
  isLoop = false
  allowautoseek = false
  loop = false
  
  startOut, endOut = reaper.GetSet_LoopTimeRange(isSet, isLoop, startOut, endOut, allowautoseek)
  if startOut and endOut == 0 then
    loop = false
  else
    loop = true
  end
  
  return loop, startOut, endOut  
end

function mediaItemInLoop(mediaItem, startLoop, endLoop)
  mposition = reaper.GetMediaItemInfo_Value(mediaItem, "D_POSITION")
  mlength = reaper.GetMediaItemInfo_Value (mediaItem, "D_LENGTH")
  mend = mposition + mlength

  if mposition == startLoop and mend <= endLoop then
    test = true
  else test = false
  end
  return test
end

function cropNewTake(mediaName, tracknumber_Out, FXname)--Crop to new take and change name to add FXname
  mediaItem = mediaName
  track = tracknumber_Out - 1
  
  fxName = FXname
    
  reaper.Main_OnCommand(40131, 0)
  
  currentTake = reaper.GetMediaItemInfo_Value(mediaItem, "I_CURTAKE")
  
  take = reaper.GetMediaItemTake(mediaItem, currentTake)
  
  reval, oldString = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", fxName, 0)
  
  reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", oldString.." - "..fxName, 1)

  render = true
  return render
end

function setNudge()
  reaper.ApplyNudge(0, 0, 0, 0, 1, false, 0)
  reaper.ApplyNudge(0, 0, 0, 0, -1, false, 0)
end

function main() --main part of the script
  debug ("") --Clears Log
    
  inst = true --used to instatiate a FX later
  moveBool = false
  render = false
  loopPoints = false
  
  checkSel = countSelected()--Makes sure that there is a MediaItem selected
  if checkSel == true then
    reaper.Undo_BeginBlock()
    mediaName = getSelectedMedia()--mediaName is our selected Media Item
    ret_val, tracknumber_Out, itemnumber_Out, fxnumber_Out, window = checkSelectedFX()--Yea! An FX is selected!
    if ret_val == 1 and window then
        
      FXName, FXmediaTrack = getFXname(tracknumber_Out, fxnumber_Out)--Get FX name, and FX Track
      
      loopPoints, startLoop, endLoop = getLoopSelection()
        if loopPoints then
          test = mediaItemInLoop(mediaName, startLoop, endLoop)
          if test then
            reaper.Main_OnCommand(41385, 0)--Fit items to time selection, padding with silence
          else debug ("Loop is not equal to MediaItem Length")
          end        
        else 
        end
      
      selTrack = reaper.GetMediaItem_Track(mediaName)
     
      moveBool = reaper.MoveMediaItemToTrack(mediaName, FXmediaTrack)--move item to FX track
     
      bypassUnfocusedFX(FXmediaTrack, fxnumber_Out, render)--Bypass all FX except desired FX
     
      reaper.Main_OnCommand(40209, 0)
      
      render = cropNewTake(mediaName, tracknumber_Out, FXName)--Crop to new take
      
      moveBool = reaper.MoveMediaItemToTrack(mediaName, selTrack)--moveback to original track
       
      bypassUnfocusedFX(FXmediaTrack, fxnumber_Out, render)--unbypass all FX except desired FX
      
      setNudge()
           
    else
      debug ("Must be a TRACK FX")
      return
    end
  
  reaper.Undo_EndBlock("Audiosweet Render", 0)
  else
    return
  end
end
 reaper.PreventUIRefresh(1)
main()
reaper.PreventUIRefresh(-1)




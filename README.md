# OptionsDVRWorkbench

A bare-bones video player/viewer for inspection video recorded using OptionsDVR.

This project is based on limited real-world exposure to OptionsDVR output, so some assumptions are involved. In particular, it assumes the following folder structure:

```text
<BaseFolder>\Data\<VesselCode>\<Options_Overlay_Hierarchy>\<VehicleName>\<video folders + files>
<BaseFolder>\Anomaly\<VesselCode>\<Options_Overlay_Hierarchy>\<VehicleName>\<anomaly media>
<BaseFolder>\Stills\<VesselCode>\<Options_Overlay_Hierarchy>\<VehicleName>\<video grabs>
```

`<BaseFolder>`, `<VesselCode>` and `<VehicleName>` are configurable before loading.

Configure one `<VehicleName>` per ROV/AUV used on the job.

## Planned Features

### Enhanced Video Playback

- Fast forward and rewind controls
- Mouse wheel seek (±3 seconds)
- Spacebar pause/resume
- Frame/image capture
- Audio level meter
- Audio spectrogram to quickly identify periods of commentary or activity
- Improved playback timeline, potentially using an industrial-style three-tab trackbar

### Anomaly Review Tools

- Capture and save images directly to the appropriate Anomaly folder
- Generate trimmed anomaly video clips using ffmpeg
- Save generated clips directly to the appropriate Anomaly folder
- Use a three-tab timeline to mark clip start, current position, and end points

### Vehicle Position Integration

OptionsDVR stores vehicle position data alongside the video. Planned features include:

- Displaying current vehicle position during playback
- Plotting vehicle movement on an Easting/Northing chart
- Broadcasting a simulated GPS/NMEA position stream for external applications such as QGIS
- Synchronising video playback with GIS mapping tools

### Database and Performance

- Eliminate the need to rescan video folders on every startup
- Store video metadata in SQLite for faster loading and searching
- Support portable deployments on external drives by optionally storing relative paths instead of absolute paths
- Provide automatic database rebuild and validation tools

### Events and Inspection Logs

- Locate video by vehicle and timestamp
- Import inspection logs and event lists from Excel
- Support flexible column mappings to accommodate client-specific formats
- Jump directly from an event or log entry to the nearest video timestamp
- Link anomaly records, still images, and video clips to imported events

## Licence

The OptionsDVRWorkbench code and executable are released under GPL-3.0.

You are free to use, distribute and modify this software, but please keep the acknowledgements intact.

## Build information

## Build Information

This project is currently developed and tested using:

- Lazarus Trunk (4.8)
- Free Pascal Compiler 3.2 Fixes Branch

### Required Packages

The following packages are required from InspectorMike Common:

- IM_units.lpk
- IM_application.lpk

Repository:

https://github.com/mikecornflake/InspectorMike-common

These packages have the following additional dependencies, available through the Lazarus Online Package Manager (OPM):

- cryptini.lpk
- flvectorialpkg.lpk
- LaSerialPort.lpk
- SynEdit.lpk
- TurboPowerIPro.lpk
- zcomponent.lpk

### Video Playback

Video playback is provided by UW_MPVPlayer:

https://github.com/URUWorks/UW_MPVPlayer

Required package:

- uwmpvplayer.lpk

### MPV Runtime

A copy of `libmpv-2.dll` must be available at runtime.

The DLL may be located in any of the following locations:

- A directory included in the system `PATH`
- The same directory as `OptionsDVRWorkbench.exe`
- An `mpv` subdirectory beneath the application folder

For example:

```text
OptionsDVRWorkbench.exe
libmpv-2.dll
```
or
```text
OptionsDVRWorkbench.exe
mpv\libmpv-2.dll
```

## Acknowledgements

Many thanks to the developers of:

- Lazarus
- Free Pascal
- mpv
- URUWorks UW_MPVPlayer

This project uses the mpv DLL for video playback:

https://github.com/mpv-player/mpv

The Free Pascal mpv wrapper is by URUWorks:

https://github.com/URUWorks/UW_MPVPlayer

I have made some local changes to that wrapper. My branch is here:

https://github.com/mikecornflake/UW_MPVPlayer

## Who am I?

Mike Thompson — CSWIP 3.4U Subsea Inspection Engineer and developer.
https://wiki.freepascal.org/User:Mike.cornflake
https://github.com/mikecornflake


## Why release this?

To fill a gap in OptionsDVR workflows.

## Is this free?

Yes.

Just keep the acknowledgements.

## Can I modify it?

Yes.

Please keep the acknowledgements and consider offering useful changes back to Mike Thompson, URUWorks, or the mpv team, depending on which part of the code you modify.

## Can I make money from my version?

Yes.

Just comply with the GPL-3.0 licence and keep the acknowledgements.

## Display devices ##
DiaporamaCenter is a multi display application. It manages the displays in an independent way :
- it is able to play & stop one different slide show on each display
- it can power on / off each device separately (this feature may depends on the OS).

## Videoprojectors ##
Videoprojectors are special devices, they
have a limited life of bulb, so they need to be shut down (or put in stand by) as soon as they are not used.
Most of videoprojectors are controllable through a serial link. DiaporamaCenter can use that way to switch on/off automatically videoprojectors. The user enters once the command codes for a videoprojector, and saves them in the configuration file. Then, each time that videprojector is identified, DiaporamaCenter automatically loads that configuration file, and the videoprojector is ready to be controlled.

## Diaporamas ##
A diaporama is a set of slides displayed on one device. As they are HTML based, slides can contain any kind of media. Each slide is generated from a fragment of data contained in the diaporama file, and the slide's template.
Diaporamas can contain slides of different template.

## Download ##
Diaporamas data and media files can be downloaded. By this way, diaporamas can be automatically updated. At this moment, only HTTP download is supported, but other protocols may be added.

## Cache ##
DiaporamaCenter uses a cache (also called repository) to store generated slides, downloaded media files. By using a cache, DiaporamaCenter can be used offline.

## Scheduler ##
_To be continued_
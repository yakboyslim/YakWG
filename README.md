# YakWG
----
## What's it do?
This program will open log files and determine areas of WOT and suggest WG Feedforward values based on the WG Final and PUT difference.

----
## How to use

1. Change first row of variables variables.csv file to match your logs.(I_INH is optional) **The trick here is to remove any spaces and replace special characters with _**
2. Copy the x-axis scalars into x_axis.csv and y-axis scalars into y_axis.csv (Either what you have stock, or what you want to use if shifting axis values)
4. Click the WG_Tuner.exe
5. Select your log. Can select multiple at once.
6. Choose FF or SWG logic
7. Choose fudge factor and trim values. Defaults should work fine.
8. The program executes and will show a few plots, but more importantly output two results files in the same folder as the logs came from. Only cells for which data was found in the logs will have recommended values. Feel free to enter these values, but as always use caution and common sense. Smooth as necessary into surrounding cells.

----
## How to install
1. Download an installer from the releases tab.
2. Open this file, and approve any security requests.
The installer and program were compiled using MATLAB. On first install you may need to install the MATLAB runtime environment from the internet.

## Optional PIDS
### lv_inh_put_ctl_i|"Flag to inhibit PUT Controller I share"
#### S50
PUT I Inhibit,x,%01.0f,0xd0000b76,1,FALSE,0,1,-1000,1000,0,TRUE
#### A05
PUT I Inhibit,x,%01.0f,0xd00005b8,1,FALSE,0,1,-1000,1000,0,TRUE

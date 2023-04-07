# YakWG
----
## What's it do?
This program will open log files and determine areas of WOT and suggest WG Feedforward values based on the WG Final and PUT difference.

----
## How to use
1. Change first row of variables variables.csv file to match your logs. (TOL, BOL, and I_INH are optional)
2. Copy the x-axis scalars into exh_axis.csv and y-axis scalars into int_axis.csv
3. Click the WG_Tuner.exe
4. Select your log. Can select multiple at once.
5. The program executes and will output two results files in the same folder as the logs came from. Only cells for which data was found in the logs will have recommended values. Feel free to enter these values, but as always use caution and common sense. Smooth as necessary into surrounding cells.

----
## How to install
1. Download an installer from the releases tab.
2. Open this file, and approve any security requests.
The installer and program were compiled using MATLAB. On first install you may need to install the MATLAB runtime environment from the internet.

## PIDS
### lv_inh_put_ctl_i|"Flag to inhibit PUT Controller I share"
#### S50
PUT I Inhibit,x,%01.0f,0xd0000b76,1,FALSE,0,1,-1000,1000,0,TRUE
#### A05
PUT I Inhibit,x,%01.0f,0xd00005b8,1,FALSE,0,1,-1000,1000,0,TRUE

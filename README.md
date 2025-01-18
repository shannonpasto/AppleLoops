# AppleLoops
Download and install Apple loops

A Jamf shell script to download and install Apple Loops for GarageBand, Logic Pro or MainStage.

I have provided 2 dmg files which you can upload to Jamf to install the loops and preference file to supress any messages about missing loops. Using these dmgs will mean users won't need to build the loop index. When you upload, make sure you select "Fill user templates (FUT)" and "Fill existing user home directories (FEU)" in the Options tab when uploading. MainStage does not need an index database. Currently only the dmgs for garageband1047 and logicpro1110 are available.

To use:
1) upload the script to Jamf
2) Create a new policy and add the script. Optionally set parameter 4 to the app identifier. Current app identifiers are below. You can find the app identifier inside the app bundle (/Applications/\<app name\>/Contents/Resources) if you're not using the latest version. It is a plist file and will be named similar to what is shown below. You can specificy more than 1 identifier, just separate with a space, eg "garageband1047 mainstage362" (without the quotes). If this is parameter is not set, the script with search /Applications for any/all apps.

   GarageBand - garageband1047

   Logic Pro - logicpro1110

   Main Stage - mainstage362

3) Add the corresponding dmg(s) to your policy (optional)
4) Scope in your target devices
5) Set you exection event and save

## Caveats
- Don't open the app until after you have installed the loops as the loops may not register correctly

# AppleLoops
Download and install Apple loops

A Jamf shell script to download and install Apple Loops for GarageBand, Logic Pro or MainStage.

Requires jq to be installed. macOS versions less than Sequoia (15) will need to have [jq](https://jqlang.github.io/jq/) installed manually.

To use:
1) upload the script to Jamf
2) Create a new policy and add the script. Set parameter 4 to the app identifier. Current app identifiers are below. You can find the app identifier inside the app bundle (/Applications/\<app name\>/Contents/Resources) if you're not using the latest version. It is a plist file and will be named similar to what is shown below

   GarageBand - garageband1047

   Logic Pro - logicpro1110

   Main Stage - mainstage362

3) Scope in your target devices
4) Set you exection event and save

## Caveats
- Don't open the app until after you have installed the loops as the loops may not register correctly

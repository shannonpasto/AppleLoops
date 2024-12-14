# AppleLoops
Download and install Apple loops

A Jamf shell script to download and install Apple Loops for GarageBand, Logic Pro or MainStage.

Requires jq to be installed. macOS versions less than Sequoia (15) will need to have [jq](https://jqlang.github.io/jq/) installed manually.

To use:
1) upload the script to Jamf
2) Create a new policy and add the script. Set parameter 4 to the app identifier. Current versions are as follows. You can find the product identifier inside the app bundle (Contents/Resources) if you're not using the latest version

   GarageBand - garageband1047

   Logic Pro - logicpro1081

   Main Stage - mainstage362

3) Scope in your target devices
4) Set you exection event and save


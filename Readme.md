Multipeer Connectivity + iBeacon proof-of-concept iOS app
=========================================================

This app does the following:

1) Discovers nearby devices using MultiPeer Connectivity (uses WiFi + Bluetooth, no internet connection needed) and shows their location on a map
2) As soon as device's location is known, it advertises the location using Multipeer Connectivity (latitude, longitude, horizontal accuracy)
3) Connects to a nearby device (by selecting the particular device on the map)
4) After a MPC connection is established, a message is sent to the connected device to turn on its iBeacon advertisement
5) The connected device replies with a message indicating that the iBeacon advertisement was turned on and specifies the iBeacon region it uses
6) The app starts iBeacon ranging for the iBeacon region received in the previous step
7) Distance from the ranged iBeacon is displayed in a annotation view
8) By tapping the star, the app will monitor the particular device and display a local notification if spotted nearby

NOTES: all key-value pairs advertised by MPC should not be larger than 400 bytes to fit into a single bluetooth packet.

![alt text](https://github.com/tomaskraina/mpc-ibeacon-test/raw/master/AppScreenshot.png "Multipeer Connectivity + iBeacon proof-of-concept iOS app screenshot")


The app requires iOS SDK 7.0+

Contact
-------
Tom Kraina, me@tomkraina.com
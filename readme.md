#Phone into Joystick

###turn your smartphone into a Bluetooth LE joystick

combination iOS app + MacOSX app creates a virtual HID joystick with multiple analog axis mapped to the orientation sensors in the phone

![animation](http://robbykraft.com/joystickphone.gif)

#great for Oculus Rift

the presence I experienced in virtual reality was disrupted when keyboard-walking jerked me out of place. analog sticks solve this problem, and since smartphones outnumber joysticks **[citation needed]** nobody needs to get jerked around.

only works in joystick-enabled games

#not for gaming

gamers are used to being jerked around (hah). (no, seriously) this controller is slow, and you will get fragged.

#setup

1. run OSX app (it’s a status bar app), it auto-begins searching for a device
2. connect through the iOS app (for connection status check OSX app)

#usage

hold the phone like a cafeteria tray, with the home button on the right

### axis map

* 1: pitch
* 2: roll
* 3: yaw

###touch screen to re-calibrate joystick

it’s helpful to re-calibrate your physical orientation against gravity. a screen touch forces the identity matrix on the controller, release and the device is facing (the new) forward.

#thank you

Virtual HID driver by [Alexandr Serkov](https://code.google.com/u/alexandr.serkov/) (alxn1)

#license

MIT
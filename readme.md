# virtual reality controller

Most games seemingly insist on incorporating keyboard-movement in virtual reality, despite the presence (VR immersion) that the Oculus Rift delivers basically falls apart when keyboard-walking jerks the user out of their place. Analog sticks solve this problem, and since smartphones outnumber joysticks **[citation needed]** nobody needs to get jerked around.

# not for gaming

gamers are used to being jerked around (hah). (no, seriously) this controller is slow, and you will get fragged.

![animation](http://robbykraft.com/joystickphone.gif)

creates a virtual HID joystick with 3 analog axis (pitch, roll, yaw) mapped to the orientation sensors in the phone

* only works in joystick-enabled games

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
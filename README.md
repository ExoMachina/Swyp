Swÿp
===========
main branch at github.com/swyp/swyp

Quickstart
---------------
1. Checkout Swyp Photos git@github.com:swyp/swypPhotos.git // https://github.com/swyp/swypPhotos
2. pull submodules: git submodule update -r --init
3. compile and try out code
4. to get into new app: fork and checkout git@github.com:swyp/swyp.git
5. Add path to swyp/libswyp to project settings -> build settings -> header search paths
6. Add swyp as target dependency in project settings->targetName->Build Phases
7. Link Binary With Library "libswyp.a" in Build Phases
8. Import <libswyp/libswyp.h> wherever needed
9. Checkout Swyp Photos project for intro to implementation!

About Swÿp
----------------
Pronounced 'Swipe.' The goal of Swyp is to allow any two apps to communicate with each other with a simple gesture bridging two touch screens.

Interoperability
---------------
The core principal of Swyp is "if you export data, you support png."

* Swyp apps will have native file formats, and usually support many formats, but they must export PNG.
* Swyp supports streaming-data pathways for music, video, or multiplayer games.
	* This is not an excuse not to support PNG export
	* Get creative! Send album art, a frame from the video, or user's game stats 
	* iOS tip-- (just render a special UIView layer into an image context, then into a PNG!) 
* View the protocol outline included in 'SwypProtocol.md'

Implementation
---------------
* Everything in Swyp built on bonjour, sockets and streams
	* Though this is iOS code, there's no reason it can't be brought to Android and OSX
* Swyp is peer to peer
	* Swyp supports Wifi and Bluetooth pan (in supporting devices like iOS devices) -pending @ iOS 5
	* Swyp visually presents the user with all enabled Swyp pathways (so that users know to connect to the same WiFi, for example, or turn on bluetooth)
	* Swyp could eventually be extended to support connections over cellular connections, providing a service (like Bump's) was created by some future party
* Swyp currently is as secure as the host network
	* If the feature is widely requested, we can implement a tls certificate system as an extension
	* Insecure networks will have insecure file transfer, making Swyp about average in security 
	
Authorship
-------------
This project was started by Alexander List of ExoMachina, then brought to the MIT Media Lab Fluid Group in 2011.

License 
--------------
This software is licensed under the MIT License with the provisions found in the next section. See the LICENSE file for all details.

Provisions
---------------
* You are not permitted to distort the Swyp protocol in a way that breaks or alters interoperability between Swyp apps (see 'Interoperability' above)
	* You must test your software application's interoperability if you wish to publish it
	* You are free to use pieces of this software, however these pieces may not be called "Swyp or Swipe" and must not claim Swyp compatability
* You may not claim to be endorsed by Swyp, ExoMachina, the MIT Media Lab or it's subsidiaries (without permission)
* You may not use ExoMachina's "Swyp" trademark as the first word in a published application without ExoMachina's permission
	* Our intent is to reserve the trademark for developers of super-legit quality apps, so if you're one, email "hello@exomachina.com"

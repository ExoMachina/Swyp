Here is the v1 swyp protocol specification; all future versions of swyp should cooperate well with it

- [ ] 1 All devices listen for "swyp" services on bonjour/multicast dns locally
        a multicast dns browser searches for "swyp" services on "tcp" in the local network
	On ios, it might be:  [_serverBrowser searchForServicesOfType:@"_swyp._tcp." inDomain:@""];
- [ ] 2 As a finger touches down on a device, it preemptively posts
      itself as a tcp server and registers with bonjour on the local network as a "swyp" service
      under the expectation that a complete swyp might be made to another device
    - [ ] If the full swipe-off the screen gesture recognizer fails, the server
          removes itself as a bonjour service
    - [ ] Otherwise, If the gesture recognizer recognizes/completes, it waits
          around for a client connection for some generous time interval like 5 seconds
- [ ] 3 All clients that see a new server store it in a set of potential
      servers (as references to their dns records)
- [ ] 4 If a client recognizes/receives a swyp gesture onto the screen, it tries to connect
      to each server listed in its set of potential servers
    - [ ] Resolving for the ip/host first through DNS 
              Helpful url: http://lists.apple.com/archives/apple-cdsa/2005/Oct/msg00035.html
    * [ ]  then making a tcp connection
- [ ] 5 After connecting, the client sends a hello packet - in the following () are comments
    - [ ] All headers are UTF8 strings, the following outline should be understood as a json object
    - [ ] See below for an example client hello
    - [ ] (headerDescriptorLength)1234;{type="swyp/controlpacket",
          tag:"clientHello", length:(payloadlength)1234}
        - [ ] { intervalSinceSwypIn:(miliseconds)23123,
        - [ ] supportedFileTypes:{
                  In order of preference
            - [ ] "video/mpeg","image/png"},
            - [ ] sessionHue:"0.99,0.44,0.69,0.72" (rgba) 
                      background set to this color, color set to connection indicator
        - [ ] }
- [ ] 6 The server sends its hello packet
    - [ ] Accepting
        - [ ] (headerDescriptorLength<StringInt>);{type="swyp/controlpac
              ket", tag:"serverHello", length:(payloadlength)}
            - [ ] {status:"accepted", swypOutVelocity:(mm/second,
                  ie,200)
            - [ ] supportedFileTypes:{
                      In order of preference
                - [ ] "video/mpeg","image/png"}
            - [ ] }
    - [ ] Or Rejecting
        - [ ] (headerDescriptorLength<StringInt>);{type="swyp/controlpac
              ket", tag:"serverHello", length:(payloadlength)}
            - [ ] {status:"rejected"}  
- [ ] 8 Now with the same message spec, we can send photos just by either
      party sending
    - [ ] (descriptorLength);{tag:"tagForStuff", type:"image/png",
          payloadLength:(NSUInteger)}(PayloadData)

example, (')s are references to data "actually on wire"-- rediculous decimal precsion is not required:
	clientHelloHeader	=	'74;{n "tag" : "clientHello",n "type" : "swyp/ControlPacket",n "length" : 140}'	
	clientHelloPayload	=	'{n "supportedFileTypes" : ["image/jpeg"],n "sessionHue" : "0.990000,0.440000,0.690000,0.720000",n "intervalSinceSwypIn" : 1.308031022548676}'


See https://github.com/alist/swyp-python/blob/master/swypConnectionSession.py for an example of a client header specified with escapes in python

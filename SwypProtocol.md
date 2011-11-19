Here is the provisional swyp protocol specification; rows that mention cryptoV2 are not yet implemented

- [ ] 1 All devices listen for "swyp" services on bonjour local
          [_serverBrowser searchForServicesOfType:@"_swyp._tcp." inDomain:@""];
- [ ] 2 As a finger touches down on a device, it preemptively posts
      itself as a tcp server and registers with bonjour as "swyp"
    - [ ] If the gesture recognizer fails the gesture, the server
          removes itself
    - [ ] Otherwise, If the gesture recognizer recognizes, it waits
          around for a client connection for some generous time interval
- [ ] 3 All clients see a new server, keeps it in a set of potential
      servers (as dns-references)
- [ ] 4 If a client recognizes a swyp gesture, then it tries to connect
      to each server listed in its set of potential servers
    - [ ] Resolving for the ip/host first
              Helpful url: http://lists.apple.com/archives/apple-cdsa/2005/Oct/msg00035.html
    * [ ]  then making a tcp connection
- [ ] 5 After connecting, the client sends a hello packet
    - [ ] (headerDescriptorLength);{type="swyp/controlpacket",
          tag:"clientHello", length:(payloadlength)}
        - [ ] { intervalSinceSwypIn:(miliseconds<StrInt>),
        - [ ] supportedFileTypes:{
                  In order of preference
            - [ ] "video/mpeg","image/png"},
            - [ ] sessionHue:"color:#0000ff" 
                      Color set to background, color set to connection indicator
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

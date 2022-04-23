import net
import json
import options
import random
import math
import nativesockets
import strutils
import bitops
import argparse
import hashids
import std/sha1

type
    DH = object
        pub: int
        base: int
        prime: int

    KEYCHAIN = object
        private: int
        public: int
        serverPublic: int
        sharedKey: string
        sharedSecret: int
        hashIds: Hashids

    MSG = object
        msg: string
        `pub`: Option[int]

proc power(a, b, p: int): int =

    var x: int = a
    var y: int = b
    var res:int = 1

    x = x mod p

    while y > 0:
        if bitand(y , 1) == 1:
            res = (res * x) mod p

        y = floorDiv(y, 2)
        x = (x * x) mod p
    return res

proc getRandomPrime(): int =

    var prime:int = 5023

    randomize()
    const randRange: int = 2000
    let randHigh: int = rand(3000..10000)
    let randLow: int = randHigh - randRange

    for n in countdown(randHigh, randLow):
        var isPrime = true

        for num in countdown(floorDiv(n, 2), 2):
            if n mod num == 0:
                isPrime = false
        
        if isPrime:
            prime = n
            break

    return prime

proc calcPublicKey(g, x, p: int): int =
    return power(g, x, p)

proc calcSecretKey(s, k, p: int): int =
    return power(s, k, p)

proc toString(str: seq[char]): string =
    result = newStringOfCap(len(str))
    for ch in str:
        add(result, ch)

proc encodeMsg(m: string, h: Hashids): string =
    #let hid: Hashids = createHashids(k & s)
    return h.encode(m.mapIt(it.ord))

proc decodeMsg(m: string, h: Hashids): string =
    var 
        d: seq[int] = h.decode(m)
        c: seq[char] = d.mapIt(it.chr)
    return toString(c)

proc verifyServer(j: JsonNode, k: string): KEYCHAIN = 
    let 
        dh: DH = to(j, DH)
        privateKey: int = getRandomPrime()
        primeNumber: int = dh.prime
        primitiveRoot: int = dh.base
        serverPubKey: int = dh.pub
        publicKey: int = calcPublicKey(primitiveRoot, privateKey, primeNumber)
        secret: int = calcSecretKey(serverPubKey, privateKey, primeNumber)
        hids: Hashids = createHashids(k & $secret)
    return  KEYCHAIN(private: privateKey, public: publicKey, serverPublic: serverPubKey, sharedKey: k, sharedSecret: secret, hashIds: hids)

proc parseServerVerification(j: JsonNode, h: Hashids): bool =
    var 
        rMsg: MSG = to(j, MSG)
        mymsg = rMsg.msg
        dec = secureHash(encodeMsg("Connected", h))

    if $dec == mymsg:
        return true
    else:
        return false

proc getCommand(): string =
    stdout.write("nsh> ")
    return stdin.readLine()

proc main(port: int, target, key: string, ssl, verbose: bool) =    

    let client: Socket = newSocket()
    var
        keychain: KEYCHAIN
        giveShell: bool = false

    # Wrap SSL, if true
    if ssl:
        var ctx = newContext(verifyMode = CVerifyNone)
        wrapSocket(ctx, client)

    # Connect to server
    try: 
        client.connect(target, Port(port))
    except:
        client.close()
        echo "Client: unable to connect"
        quit(2)

    if verbose:
        echo "Client: connected to server on address " & $target & ":" & $port

    # Parse Response
    var 
        recvJson: string 
        jsonData: JsonNode

    try:
        recvJson = client.recvLine(timeout = 10)
    except TimeoutError:
        client.close()
        echo "Client: unable to connect. SSL?"
        quit(2)
    
    try:
        jsonData = parseJson(recvJson)
        keychain = verifyServer(jsonData, key)
    except JsonParsingError:
        echo "Client: authentication failed"
        client.close()
        quit(2)

    # Generate salted shared secret as sha1 hash
    # Generate JSON object to send to server
    try: 
        let 
            idMsg = secureHash(encodeMsg("Success", keychain.hashIds))
            jsonObject = %* {"pub": keychain.public, "msg": $idMsg}  

        # Send public key and salted shared secret as sha1 hash
        client.send($jsonObject & "\r\L")

        # Receive response from server and parse JSON
        recvJson = client.recvLine(timeout = 10)
        jsonData = parseJson(recvJson)

        # Verify shared secret
        giveShell = parseServerVerification(jsonData, keychain.hashIds)
    except JsonParsingError:
        echo "Client: authentication failed or SSL?"
        client.close()
        quit(2)

    # Start shell and run commands
    if giveShell:
        var 
            run = true
            command: string
        
        while run:
            command = getCommand()

            case command:
                of "exit":
                    run = false
                of "shutdown":
                    run = false
                    client.send(encodeMsg(command, keychain.hashIds) & "\r\L")
                of "upload":
                    let uploadFile = command.split()[1]
                    if fileExists(uploadFile):
                        let fileContents = readFile(uploadFile)
                        client.send(encodeMsg(fileContents, keychain.hashIds) & "\r\L")
                    else:
                        echo "Client: file not found"
                of "help":
                    echo "exit\tshutdown\tupload\tdownload"
                of "help exit":
                    echo "exit: Exit the shell"
                of "help shutdown":
                    echo "shutdown: Shutdown the server and exit"
                of "help upload":
                    echo "upload <path-on-client>: Upload file. Requires full path and uploads to current dir on server"
                of "help download":
                    echo "download <file-on-server>: Download file. Requires full path and filename"
                else:
                    client.send(encodeMsg(command, keychain.hashIds) & "\r\L")

            if run:
                var isData: bool = true
                while isData:
                    let receive: string = client.recvLine()
                    if receive == "\r\L":
                        isData = false
                    else:
                        echo decodeMsg(receive, keychain.hashIds)

        client.close()

var p = newParser:
    help("Nim-shell client")
    flag("-s", "--ssl", help="Enable SSL")
    flag("-v", "--verbose", help="Enable verbose output")
    option("-p", "--port", help="Target port", required=true)
    option("-t", "--target", help="Target IP", required=true)
    option("-k", "--key", help="Secret key", required=true)
    
try: 
    var x = p.parse(commandLineParams())
    echo x.target
    
    main(parseInt(x.port), x.target, x.key, x.ssl, x.verbose)
except ShortCircuit as e:
    if e.flag == "argparse_help":
        echo p.help
        quit(1)
except UsageError:
    stderr.writeLine getCurrentExceptionMsg()
    quit(1)
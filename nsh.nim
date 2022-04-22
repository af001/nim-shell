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
        hashid: Hashids

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

proc main(port: int, target, key: string, ssl: bool) =    

    let client: Socket = newSocket()

    if ssl:
        var ctx = newContext(verifyMode = CVerifyNone)
        wrapSocket(ctx, client)

    client.connect(target, Port(port))
    stdout.writeLine("Client: connected to server on address " & $target & ":" & $port)

    # Parse Response
    var recvJson = client.recvLine(timeout = 10)
    var keychain: KEYCHAIN
    var giveShell: bool = false

    try:
        var jsonData = parseJson(recvJson)
        let 
            dh: DH = to(jsonData, DH)
            privateKey: int = getRandomPrime()
            primeNumber: int = dh.prime
            primitiveRoot: int = dh.base
            serverPubKey: int = dh.pub
            publicKey: int = calcPublicKey(primitiveRoot, privateKey, primeNumber)
            secret: int = calcSecretKey(serverPubKey, privateKey, primeNumber)
            hid: Hashids = createHashids(key & $secret)
            idMsg = secureHash(hid.encode("Success".mapIt(it.ord)))
            jsonObject = %* {"pub": publicKey, "msg": $idMsg}  

        keychain = KEYCHAIN(private: privateKey, public: publicKey, serverPublic: serverPubKey, hashid: hid)

        client.send($jsonObject & "\r\L")

        recvJson = client.recvLine(timeout = 10)
        jsonData = parseJson(recvJson)
        var rMsg: MSG = to(jsonData, MSG)
        var mymsg = rMsg.msg
        #var dec: seq[int] = hid.decode(mymsg)
        var dec = secureHash(hid.encode("Connected".mapIt(it.ord)))

        if $dec == mymsg:
            echo "Authentication successful"
            giveShell = true

    except JsonParsingError:
        echo "Authentication failed"
        client.close()

    var run = true

    if giveShell:
        while run:
            stdout.write("> ")
            let command: string = stdin.readLine()

            if command == "exit":
                run = false
            else:
                client.send(command & "\r\L")

                if command == "shutdown":
                    run = false
                else:
                    var isData: bool = true
                    while isData:
                        let receive: string = client.recvLine()
                        if receive == "\r\L":
                            isData = false
                        else:
                            echo receive

        client.close()

var p = newParser:
    help("Nim-shell client")
    flag("-s", "--ssl", help="Enable SSL")
    option("-p", "--port", help="Target port", required=true)
    option("-t", "--target", help="Target IP", required=true)
    option("-k", "--key", help="Secret key", required=true)
    
try: 
    var x = p.parse(commandLineParams())
    echo x.target
    
    main(parseInt(x.port), x.target, x.key, x.ssl)
except ShortCircuit as e:
    if e.flag == "argparse_help":
        echo p.help
        quit(1)
except UsageError:
    stderr.writeLine getCurrentExceptionMsg()
    quit(1)

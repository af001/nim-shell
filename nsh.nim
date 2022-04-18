import net

let client: Socket = newSocket()
client.connect("127.0.0.1", Port(4444))
stdout.writeLine("Client: connected to server on address 127.0.0.1:4444")
var run = true

while run:
    stdout.write("> ")
    let command: string = stdin.readLine()

    if command == "quit":
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

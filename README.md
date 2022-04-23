# nim-shell
A simple bind shell written in NIM. 

This project contains a server (nshd) that acts as a backdoor on a server. The server will bind to a port and can be configured communicate over SSL. The client is the interactive shell that is used to communicate with the backdoor. This code is for learning purposes only.

#### Configuration
The server secret and cert/key that are in nshd.nim should be changed. The default password is "1234" with self-signed certs. These keys can be observed hardcoded in the binary after compile time. 

Generate certs
```
openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout mykey.pem -out mycert.pem
```

#### Compile
```
nim compile -d:ssl --passC:-flto -d:danger tsh.nim
nim compile -d:ssl --passC:-flto -d:danger tshd.nim
```

#### Usage
```
# Server
./tshd -p 1011 -v

# Client
./tsh -p 1011 -t 192.168.0.3 -k 1234 --ssl -v
```

#### Future 
1. daemonize nshd
2. Upload and download feature

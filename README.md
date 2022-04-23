# nim-shell
A simple bind shell written in NIM. 

This project contains a server (nshd) that acts as a backdoor on a server. The server will bind to a port and can be configured communicate over SSL. The client is the interactive shell that is used to communicate with the backdoor. This code is for learning purposes only.

#### Configuration
The server secret and cert/key that are in nshd.nim should be changed. The default password is "1234" with self-signed certs. These keys can be observed hardcoded in the binary after compile time. 

Generate certs
```
openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout mykey.pem -out mycert.pem
```

#### Custom Dependencies
```
# Updated version of hashids
nimble install https://github.com/af001/nim-hashids
```

#### Compile
```
# Testing
nim compile -d:ssl --passC:-flto nsh.nim
nim compile -d:ssl --passC:-flto nshd.nim

# Static compiled for Linux
nim --passL:-static -d:release -d:ssl --opt:size c nsh.nim
nim --passL:-static -d:release -d:ssl --opt:size c nshd.nim

# Musl
wget https://musl.libc.org/releases/musl-1.2.3.tar.gz
tar xzvf musl-1.2.3.tar.gz
cd musl-1.2.3

sed -i 's/ARCH = i386/ARCH = x86_64/g'

./configure --prefix=/usr/local/musl/
make
make install

export PATH=$PATH:/usr/local/musl/bin

nim --gcc.exe:musl-gcc --gcc.linkerexe:musl-gcc --passL:-static -d:release -d:ssl --opt:size c nsh.nim 
nim --gcc.exe:musl-gcc --gcc.linkerexe:musl-gcc --passL:-static -d:release -d:ssl --opt:size c nshd.nim 

```

#### Usage
```
# Server
> $ ./nshd -h
Nim-shell server

Usage:
   [options]

Options:
  -h, --help
  -v, --verbose              Enable verbost output for debugging
  -n, --nossl                Disable SSL
  -p, --port=PORT            Override default port
  -k, --key=KEY              Override default shared secret

# Client
> $ ./nsh -h
Nim-shell client

Usage:
   [options]

Options:
  -h, --help
  -s, --ssl                  Enable SSL
  -v, --verbose              Enable verbose output
  -p, --port=PORT            Target port
  -t, --target=TARGET        Target IP
  -k, --key=KEY              Secret key
```

#### Future 
1. daemonize nshd
2. Upload and download feature

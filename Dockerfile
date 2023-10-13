FROM ubuntu as builder

RUN apt-get update && \
    apt-get -y install --no-install-recommends git-core debhelper cmake libprotobuf23 libprotobuf-dev protobuf-compiler libudev-dev make gcc g++ ca-certificates build-essential

RUN git clone -b release-0.2 https://github.com/jketterl/codecserver.git && cd codecserver && \
    dpkg-buildpackage && cd .. && \ 
    dpkg -i libcodecserver*.deb && dpkg -i codecserver_*.deb

RUN git clone https://github.com/szechyjs/mbelib.git && cd mbelib \
    && dpkg-buildpackage && cd .. && \
    dpkg -i libmbe1_*.deb libmbe-dev_*.deb

RUN git clone https://github.com/knatterfunker/codecserver-softmbe.git && cd codecserver-softmbe && \ 
    dpkg-buildpackage && cd .. && \
    dpkg -i codecserver-driver-softmbe_*.deb

FROM ubuntu 

RUN apt-get update && \
    apt-get -y install --no-install-recommends libprotobuf23 libprotobuf-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder --link /*.deb /packages/

RUN dpkg -i /packages/libcodecserver*.deb /packages/codecserver_*.deb /packages/libmbe1_*.deb /packages/libmbe-dev_*.deb /packages/codecserver-driver-softmbe_*.deb && rm -rf /packages
# RUN dpkg -i /packages/libcodecserver*.deb && dpkg -i /packages/codecserver_*.deb && dpkg -i /packages/libmbe1_*.deb && dpkg -i /packages/libmbe-dev_*.deb && dpkg -i /packages/codecserver-driver-softmbe_*.deb && rm -rf /packages

RUN cat > /etc/codecserver/codecserver.conf <<EOF
# unix domain socket server for local use
[server:unixdomainsockets]
socket=/tmp/codecserver.sock

# tcp server for use over network
[server:tcp]
port=1073
#bind=::

# example config for an USB-3000 or similar device
#[device:dv3k]
#driver=ambe3k
#tty=/dev/ttyUSB0
#baudrate=921600

[device:softmbe]
driver=softmbe
EOF

EXPOSE 1073/tcp

ENTRYPOINT ["/usr/bin/codecserver"]
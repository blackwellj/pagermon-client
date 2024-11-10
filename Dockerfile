# Use a Debian image that supports multiple architectures
FROM --platform=$TARGETPLATFORM debian:bullseye-20230109-slim

LABEL Description="Pagermon RTL-SDR client"
LABEL Vendor="blackwellj"
LABEL Version="1.0.0"

# Install dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools \
       libpulse-dev libx11-dev nodejs npm git libusb-1.0-0-dev \
       pkg-config ca-certificates git-core cmake build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Work in temporary directory for building
WORKDIR /tmp

# Blacklist the RTL-SDR driver
RUN mkdir -p /etc/modprobe.d
RUN echo 'blacklist dvb_usb_rtl28xxu' > /etc/modprobe.d/dvb-blacklist.conf

# Build and install rtl-sdr
RUN git clone git://git.osmocom.org/rtl-sdr.git
RUN mkdir /tmp/rtl-sdr/build

WORKDIR /tmp/rtl-sdr/build
RUN cmake ../ -DINSTALL_UDEV_RULES=ON -DDETACH_KERNEL_DRIVER=ON
RUN make
RUN make install
RUN ldconfig -v

# Cleanup rtl-sdr build files
WORKDIR /tmp
RUN rm -rf /tmp/rtl-sdr

# Build and install multimon-ng
RUN git clone --depth 1 https://github.com/EliasOenal/multimon-ng.git /tmp/multimon-ng
RUN mkdir /tmp/multimon-ng/build

WORKDIR /tmp/multimon-ng/build
RUN qmake ../multimon-ng.pro PREFIX=/usr/local
RUN make
RUN make install

# Clone pagermon client
RUN git clone --depth 1 --progress https://github.com/pagermon/pagermon.git /pagermon

WORKDIR /pagermon/client
RUN npm install

# Copy configuration and script files
COPY ./client_config.json /pagermon/client/config/default.json
COPY ./run.sh /
RUN chmod +x /run.sh

# Set the entrypoint
CMD ["/run.sh"]

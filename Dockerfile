# Use an ARM-compatible Debian image for Raspberry Pi
FROM arm64v8/debian:bullseye-slim

MAINTAINER James Blackwell
LABEL Description="Pagermon RTL-SDR client"
LABEL Vendor="blackwellj"
LABEL Version="1.0.0"

# Install required packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools \
    libpulse-dev libx11-dev \
    git libusb-1.0-0-dev pkg-config ca-certificates \
    cmake build-essential curl

# Install Node.js from NodeSource (for ARM compatibility)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Blacklist the DVB driver
RUN mkdir -p /etc/modprobe.d \
    && echo 'blacklist dvb_usb_rtl28xxu' > /etc/modprobe.d/dvb-blacklist.conf

# Build and install rtl-sdr
WORKDIR /tmp
RUN git clone git://git.osmocom.org/rtl-sdr.git \
    && mkdir /tmp/rtl-sdr/build

WORKDIR /tmp/rtl-sdr/build
RUN cmake ../ -DINSTALL_UDEV_RULES=ON -DDETACH_KERNEL_DRIVER=ON \
    && make \
    && make install \
    && ldconfig

# Clean up rtl-sdr sources
WORKDIR /tmp
RUN rm -rf /tmp/rtl-sdr

# Build and install multimon-ng
RUN git clone --depth 1 https://github.com/EliasOenal/multimon-ng.git /tmp/multimon-ng \
    && mkdir /tmp/multimon-ng/build

WORKDIR /tmp/multimon-ng/build
RUN qmake ../multimon-ng.pro PREFIX=/usr/local \
    && make \
    && make install

# Clone Pagermon client
RUN git clone --depth 1 https://github.com/pagermon/pagermon.git /pagermon

# Install client dependencies
WORKDIR /pagermon/client
RUN npm install

# Copy configuration and scripts
COPY ./client_config.json /pagermon/client/config/default.json
COPY ./run.sh /run.sh
RUN chmod +x /run.sh

# Set the entry point
CMD ["/run.sh"]

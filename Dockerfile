FROM alpine:latest as build

ARG TARGETPLATFORM
ARG VERSION

RUN apk --no-cache add build-base
RUN apk --no-cache add cmake
RUN apk --no-cache add libjpeg-turbo-dev
RUN apk --no-cache add linux-headers
RUN apk --no-cache add openssl
# Raspberry Pi camera support does not currently work for arm64 (and doesn't exist for amd64)
RUN [[ "${TARGETPLATFORM}" != "linux/arm64" ]] && apk --no-cache add raspberrypi-dev || true

RUN wget -qO- https://github.com/jacksonliam/mjpg-streamer/archive/master.tar.gz | tar xz

# Install mjpg-streamer
WORKDIR /mjpg-streamer-master/mjpg-streamer-experimental
RUN make
RUN make install

# Build final image
FROM alpine:latest

COPY --from=build /usr/local/bin /usr/local/bin
COPY --from=build /usr/local/lib /usr/local/lib
COPY --from=build /usr/local/share /usr/local/share

RUN apk --no-cache add ffmpeg libjpeg openssh-client v4l-utils

COPY start-mjpg-streamer /usr/local/bin/start-mjpg-streamer
RUN chmod +x /usr/local/bin/start-mjpg-streamer

ENV CAMERA_DEV /dev/video0
ENV MJPEG_STREAMER_INPUT -y -n -r 640x480

EXPOSE 8080

CMD ["/usr/local/bin/start-mjpg-streamer"]

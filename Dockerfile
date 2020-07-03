FROM alpine:latest as build

RUN apk --no-cache add build-base
RUN apk --no-cache add cmake
RUN apk --no-cache add libjpeg-turbo-dev
RUN apk --no-cache add linux-headers
RUN apk --no-cache add openssl

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
COPY --from=build /mjpg-streamer-*/mjpg-streamer-experimental /opt/mjpg-streamer

RUN apk --no-cache add bash ffmpeg libjpeg openssh-client v4l-utils

COPY start-mjpg-streamer /usr/local/bin/start-mjpg-streamer

ENV CAMERA_DEV /dev/video0
ENV MJPEG_STREAMER_INPUT -y -n -r 640x480

EXPOSE 8080

CMD ["/usr/local/bin/start-mjpg-streamer"]

FROM slok/kahoy:latest

RUN apk --no-cache add \
    git \
    curl \
    bash

ARG HELM_VERSION="v3.3.1"

RUN wget -O- https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz | \
    tar xvz -C /tmp && \
    mv /tmp/linux-amd64/helm /usr/bin


# Create user
ARG UID=1000
ARG GID=1000
RUN addgroup -g $GID app && \
    adduser -D -u $UID -G app app
USER app

WORKDIR /src

ENTRYPOINT []
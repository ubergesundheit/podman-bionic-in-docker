FROM buildpack-deps:bionic as build

# Install go
ENV PATH=$PATH:/usr/local/go/bin
ENV GOPATH=/go

RUN wget https://dl.google.com/go/go1.11.4.linux-amd64.tar.gz
RUN tar -C /usr/local -xzf go1.11.4.linux-amd64.tar.gz

RUN go version
RUN mkdir -p $GOPATH

RUN apt-get update && apt-get install -y libdevmapper-dev libglib2.0-dev libgpgme11-dev libseccomp-dev libostree-dev \
                        go-md2man libprotobuf-dev libprotobuf-c0-dev libseccomp-dev python3-setuptools

RUN git clone https://github.com/kubernetes-sigs/cri-o $GOPATH/src/github.com/kubernetes-sigs/cri-o
RUN git clone https://github.com/containernetworking/plugins.git $GOPATH/src/github.com/containernetworking/plugins
RUN git clone https://github.com/opencontainers/runc.git $GOPATH/src/github.com/opencontainers/runc
RUN git clone https://github.com/containers/libpod/ $GOPATH/src/github.com/containers/libpod

RUN cd $GOPATH/src/github.com/kubernetes-sigs/cri-o
RUN mkdir $GOPATH/src/github.com/kubernetes-sigs/cri-o/bin
RUN make -C $GOPATH/src/github.com/kubernetes-sigs/cri-o bin/conmon
RUN install -D -m 755 $GOPATH/src/github.com/kubernetes-sigs/cri-o/bin/conmon /usr/libexec/podman/conmon

RUN cd $GOPATH/src/github.com/containernetworking/plugins && ./build_linux.sh
RUN pwd
RUN mkdir -p /usr/libexec/cni
RUN cp $GOPATH/src/github.com/containernetworking/plugins/bin/* /usr/libexec/cni

RUN make -C $GOPATH/src/github.com/opencontainers/runc BUILDTAGS="seccomp"
RUN cp $GOPATH/src/github.com/opencontainers/runc/runc /usr/bin/runc

RUN make -C $GOPATH/src/github.com/containers/libpod
RUN make -C $GOPATH/src/github.com/containers/libpod install PREFIX=/usr

RUN mkdir -p /etc/containers
RUN curl https://raw.githubusercontent.com/projectatomic/registries/master/registries.fedora -o /etc/containers/registries.conf
RUN curl https://raw.githubusercontent.com/containers/skopeo/master/default-policy.json -o /etc/containers/policy.json

RUN mkdir -p /etc/cni/net.d
RUN curl -qsSL https://raw.githubusercontent.com/containers/libpod/master/cni/87-podman-bridge.conflist | tee /etc/cni/net.d/99-loopback.conf

RUN git clone https://github.com/rootless-containers/slirp4netns.git
RUN cd slirp4netns && ./autogen.sh && LDFLAGS=-static ./configure --prefix=/usr && make && make install

FROM ubuntu:bionic

COPY --from=build /usr/libexec /usr/libexec
COPY --from=build /usr/bin/runc /usr/bin/runc
COPY --from=build /usr/bin/podman /usr/bin/podman
COPY --from=build /usr/bin/slirp4netns /usr/bin/slirp4netns

COPY --from=build /etc/containers /etc/containers
COPY --from=build /etc/cni/net.d /etc/cni/net.d

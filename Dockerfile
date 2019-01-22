FROM buildpack-deps:bionic

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

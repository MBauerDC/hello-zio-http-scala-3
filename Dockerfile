FROM ghcr.io/graalvm/graalvm-ce:ol8-java17-22.1.0 as builder

WORKDIR /app
COPY . /app

RUN gu install native-image

# SEE: https://github.com/oracle/graal/blob/master/substratevm/StaticImages.md
ARG RESULT_LIB="/staticlibs"

RUN mkdir ${RESULT_LIB} && \
    curl -L -s -o musl.tar.gz https://musl.libc.org/releases/musl-1.2.3.tar.gz && \
    mkdir musl && tar -xzf musl.tar.gz -C musl --strip-components 1 && cd musl && \
    ./configure --disable-shared --prefix=${RESULT_LIB} &>/dev/null && \
    make -s && make install -s && \
    cp /usr/lib/gcc/x86_64-redhat-linux/8/libstdc++.a ${RESULT_LIB}/lib/

ENV PATH="$PATH:${RESULT_LIB}/bin"
ENV CC="musl-gcc"

RUN curl -L -s -o zlib.tar.gz https://zlib.net/zlib-1.2.12.tar.gz && \
   mkdir zlib && tar -xzf zlib.tar.gz -C zlib --strip-components 1 && cd zlib && \
   ./configure --static --prefix=${RESULT_LIB} &>/dev/null && \
    make -s && make install -s
#END PRE-REQUISITES FOR STATIC NATIVE IMAGES FOR GRAAL


RUN curl -L -o xz.rpm https://rpmfind.net/linux/centos/8-stream/BaseOS/x86_64/os/Packages/xz-5.2.4-3.el8.x86_64.rpm
RUN rpm -iv xz.rpm

RUN curl -L -o upx-3.96-amd64_linux.tar.xz https://github.com/upx/upx/releases/download/v3.96/upx-3.96-amd64_linux.tar.xz
RUN tar -xvf upx-3.96-amd64_linux.tar.xz

RUN ./sbt GraalVMNativeImage/packageBin

RUN upx-3.96-amd64_linux/upx -7 /app/target/graalvm-native-image/hello-zio-http

FROM scratch

WORKDIR /tmp

COPY --from=builder /app/target/graalvm-native-image/hello-zio-http /hello-zio-http

ENTRYPOINT ["/hello-zio-http"]

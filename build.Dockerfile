FROM debian:11-slim AS builder

WORKDIR /app

ADD https://packages.microsoft.com/config/debian/11/packages-microsoft-prod.deb packages-microsoft-prod.deb

RUN apt-get update &&  \
    apt-get install -y ca-certificates &&  \
    rm -rf /var/lib/apt/lists/*

# add microsoft repo
RUN dpkg -i packages-microsoft-prod.deb; \
    rm packages-microsoft-prod.deb

RUN apt-get update &&  \
    apt-get install -y dotnet-sdk-9.0 default-jdk zip &&  \
    rm -rf /var/lib/apt/lists/*

COPY . .

RUN dotnet build -c Release Antlr/
RUN dotnet build -c Release parseStg2/
RUN dotnet publish -r linux-x64 -p:PublishSingleFile=true --self-contained true asn1scc/asn1scc.fsproj &&  \
    cd /app/asn1scc/bin/Release/net9.0/linux-x64/publish/ && zip asn1scc.linux.x86_64.zip *
RUN dotnet publish -r win-x64 -p:PublishSingleFile=true --self-contained true asn1scc/asn1scc.fsproj &&  \
    cd /app/asn1scc/bin/Release/net9.0/win-x64/publish/ && zip asn1scc.windows.x86_64.zip *

FROM scratch
WORKDIR /

COPY --from=builder /app/asn1scc/bin/Release/net9.0/linux-x64/publish/asn1scc.linux.x86_64.zip /asn1scc.linux.x86_64.zip
COPY --from=builder /app/asn1scc/bin/Release/net9.0/win-x64/publish/asn1scc.windows.x86_64.zip /asn1scc.windows.x86_64.zip
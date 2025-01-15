FROM ubuntu:20.04

WORKDIR /usr/src/app
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \ 
    python2.7 python3 python3-pip openjdk-11-jdk git tzdata && \
    apt-get clean && \
    ln -fs /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata

RUN ln -s /usr/bin/python2.7 /usr/bin/python

RUN python3 -m pip install pymysql 

RUN git clone https://github.com/SCECcode/cybershake-tools.git

WORKDIR /usr/src/app/cybershake-tools
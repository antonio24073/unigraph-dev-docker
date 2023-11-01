FROM debian

USER root
SHELL ["/bin/bash", "-c"] 

RUN apt-get update -y
RUN apt-get install git -y
RUN apt-get install make -y
RUN apt-get install gcc -y
RUN apt-get install golang -y
RUN apt-get install curl -y
RUN apt-get install bzip2 -y
RUN apt-get install ssh -yqq

# Trying python 3.10 ppa not working
# RUN apt-get install software-properties-common -y
# RUN apt-get install python3-launchpadlib -y
# RUN add-apt-repository ppa:deadsnakes/ppa
# RUN apt-get update -y
# RUN apt-get install python3.10 -y
# # RUN echo "alias python=/usr/bin/python3.10" >> ~/.bashrc
# RUN apt-get install python3-pip -y

# Trying python 3.10 with virtualenv not working
# RUN apt-get install python3-virtualenv -y
# RUN apt-get install python3-distutils -y
# RUN find / -iname python*
# RUN py --version
# RUN rm -f /usr/bin/python && ln -s /usr/bin/python /usr/local/bin/python3.10
# RUN python3 --version
# RUN python3 -m virtualenv --python=/usr/bin/python3.10 .venv
# RUN python3 --version
# RUN source .venv/bin/activate

# python 3.10 from source
RUN apt update -y
RUN apt install build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev libsqlite3-dev wget libbz2-dev -y
WORKDIR /
ENV VERSION=3.10.13
RUN wget "https://www.python.org/ftp/python/$VERSION/Python-$VERSION.tgz"
RUN tar -xf "Python-$VERSION.tgz"
WORKDIR "/Python-$VERSION"
RUN pwd
RUN ./configure --enable-optimizations
RUN make -j $(nproc)
RUN make altinstall
# RUN python3.10 --version
RUN whereis python3.10
RUN rm -f /usr/bin/python && ln -s /usr/local/bin/python3.10 /usr/bin/python
RUN python --version

# node
ENV NODE_VERSION=16.20.0
RUN apt install -y curl
WORKDIR /
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
ENV NVM_DIR=/root/.nvm
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}
ENV PATH="/root/.nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"
RUN node --version
RUN npm --version
RUN npm install --global yarn

WORKDIR /
RUN git clone https://github.com/unigraph-dev/unigraph-dev.git
WORKDIR /unigraph-dev
RUN npm cache clean --force
RUN yarn && yarn build-deps

WORKDIR /
RUN git clone https://github.com/unigraph-dev/dgraph.git

WORKDIR /dgraph
RUN make install
RUN ls $(go env GOPATH)/bin | grep dgraph
RUN /root/go/bin/dgraph

RUN mv /dgraph /opt/unigraph
RUN chown -R $(whoami) /opt/unigraph

WORKDIR /
RUN mkdir /unigraph-dev-data

RUN chown -R $(whoami) /unigraph-dev-data
RUN chown -R $(whoami) /unigraph-dev

WORKDIR /unigraph-dev
ENTRYPOINT ./scripts/start_server.sh -d /unigraph-dev-data -b /root/go/bin/dgraph && yarn explorer-start
EXPOSE 8080



# Version: 0.4.0 06-Nov-2013
FROM sbisbee/couchdb:1.4
MAINTAINER Terin Stock <terinjokes@gmail.com>

ENV PATH /opt/node/bin/:$PATH

# Install curl
RUN apt-get install -y curl git

# Setup nodejs
RUN mkdir -p /opt/node
RUN curl -L# http://nodejs.org/dist/v0.10.21/node-v0.10.21-linux-x64.tar.gz|tar -zx --strip 1 -C /opt/node

# Download npmjs project
RUN git clone https://github.com/isaacs/npmjs.org /opt/npmjs
RUN cd /opt/npmjs; git checkout ea8e7a533ea595db79b24f12c76b62c3889b43e8
RUN npm install couchapp@0.10.x -g
RUN cd /opt/npmjs; npm link couchapp; npm install semver

# Allow insecure rewrites
RUN echo "[httpd]\nsecure_rewrites = false" >> /usr/local/etc/couchdb/local.d/secure_rewrites.ini

# Configuring npmjs.org
RUN cd /opt/npmjs; couchdb -b; sleep 1; curl -X PUT http://localhost:5984/registry; sleep 1; couchdb -d;
RUN cd /opt/npmjs; couchdb -b; sleep 1; couchapp push registry/shadow.js http://localhost:5984/registry; sleep 1; couchapp push registry/app.js http://localhost:5984/registry; sleep 1; couchdb -d
RUN cd /opt/npmjs; npm set _npmjs.org:couch=http://localhost:5984/registry
RUN cd /opt/npmjs; couchdb -b; sleep 1; npm run load; sleep 1; curl -k "http://localhost:5984/registry/_design/scratch" -X COPY -H destination:'_design/app'; sleep 1; couchdb -d
## Resolve isaacs/npmjs.org#98
RUN cd /opt/npmjs; /usr/local/bin/couchdb -b; sleep 1; curl http://isaacs.iriscouch.com/registry/error%3A%20forbidden | curl -X PUT -d @- http://localhost:5984/registry/error%3A%20forbidden?new_edits=false; sleep 1; couchdb -d

# Install npm-delegate
RUN npm install -g npm-delegate@0.2.x

# Start
ADD scripts/startup.sh /root/startup.sh
CMD /root/startup.sh

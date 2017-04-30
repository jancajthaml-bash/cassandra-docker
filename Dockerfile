FROM alpine:latest

MAINTAINER	Jan Cajthaml <jan.cajthaml@gmail.com>

ENV			CASSANDRA_VERSION=3.9.0 \
    		CASSANDRA_HOME=/opt/cassandra \
    		CASSANDRA_CONFIG=/etc/cassandra \
    		CASSANDRA_PERSIST_DIR=/var/lib/cassandra \
    		CASSANDRA_DATA=/var/lib/cassandra/data \
    		CASSANDRA_COMMITLOG=/var/lib/cassandra/commitlog \
    		CASSANDRA_LOG=/var/log/cassandra \
    		CASSANDRA_LOGS=/opt/cassandra/logs \
    		JAVA_VERSION_MAJOR=8 \
		    JAVA_VERSION_MINOR=92 \
		    JAVA_VERSION_BUILD=14 \
		    JAVA_PACKAGE=server-jre \
		    JAVA_JCE=standard \
		    JAVA_HOME=/opt/jdk \
		    PATH=${PATH}:/opt/jdk/bin \
		    GLIBC_VERSION=2.23-r3 \
		    LANG=C.UTF-8 \
		    READY_PORT=6000

RUN			mkdir -p ${CASSANDRA_DATA} \
            		 ${CASSANDRA_CONFIG} \
             		 ${CASSANDRA_HOME} \
             		 ${CASSANDRA_LOG} \
             		 ${CASSANDRA_LOGS} \
             		 ${CASSANDRA_COMMITLOG}

RUN 		apk upgrade --update && \
		    apk --update --no-cache add netcat-openbsd \
		    							wget \
		    							libstdc++ \
		    							curl \
		    							python \
		    							ca-certificates \
		    							bash \
		    							tar

RUN			set -ex && \
		    for pkg in glibc-${GLIBC_VERSION} glibc-bin-${GLIBC_VERSION} glibc-i18n-${GLIBC_VERSION}; do curl -sSL https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/${pkg}.apk -o /tmp/${pkg}.apk; done && \
		    apk add --allow-untrusted /tmp/*.apk && \
		    rm -v /tmp/*.apk && \
		    ( /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 C.UTF-8 || true ) && \
		    echo "export LANG=C.UTF-8" > /etc/profile.d/locale.sh && \
		    /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib && \
		    curl -jksSLH "Cookie: oraclelicense=accept-securebackup-cookie" -o /tmp/java.tar.gz \
		      http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-b${JAVA_VERSION_BUILD}/${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz && \
		    gunzip /tmp/java.tar.gz && \
		    tar -C /opt -xf /tmp/java.tar && \
		    ln -s /opt/jdk1.${JAVA_VERSION_MAJOR}.0_${JAVA_VERSION_MINOR} /opt/jdk && \
		    find /opt/jdk/ -maxdepth 1 -mindepth 1 | grep -v jre | xargs rm -rf && \
		    cd /opt/jdk/ && ln -s ./jre/bin ./bin && \
		    if [ "${JAVA_JCE}" == "unlimited" ]; then echo "Installing Unlimited JCE policy" && \
		      curl -jksSLH "Cookie: oraclelicense=accept-securebackup-cookie" -o /tmp/jce_policy-${JAVA_VERSION_MAJOR}.zip \
		        http://download.oracle.com/otn-pub/java/jce/${JAVA_VERSION_MAJOR}/jce_policy-${JAVA_VERSION_MAJOR}.zip && \
		      cd /tmp && unzip /tmp/jce_policy-${JAVA_VERSION_MAJOR}.zip && \
		      cp -v /tmp/UnlimitedJCEPolicyJDK8/*.jar /opt/jdk/jre/lib/security/; \
		    fi && \
		    sed -i s/#networkaddress.cache.ttl=-1/networkaddress.cache.ttl=10/ $JAVA_HOME/jre/lib/security/java.security && \
		    apk del curl glibc-i18n && \
		    rm -rf /opt/jdk/jre/plugin \
		           /opt/jdk/jre/bin/javaws \
		           /opt/jdk/jre/bin/jjs \
		           /opt/jdk/jre/bin/orbd \
		           /opt/jdk/jre/bin/pack200 \
		           /opt/jdk/jre/bin/policytool \
		           /opt/jdk/jre/bin/rmid \
		           /opt/jdk/jre/bin/rmiregistry \
		           /opt/jdk/jre/bin/servertool \
		           /opt/jdk/jre/bin/tnameserv \
		           /opt/jdk/jre/bin/unpack200 \
		           /opt/jdk/jre/lib/javaws.jar \
		           /opt/jdk/jre/lib/deploy* \
		           /opt/jdk/jre/lib/desktop \
		           /opt/jdk/jre/lib/*javafx* \
		           /opt/jdk/jre/lib/*jfx* \
		           /opt/jdk/jre/lib/amd64/libdecora_sse.so \
		           /opt/jdk/jre/lib/amd64/libprism_*.so \
		           /opt/jdk/jre/lib/amd64/libfxplugins.so \
		           /opt/jdk/jre/lib/amd64/libglass.so \
		           /opt/jdk/jre/lib/amd64/libgstreamer-lite.so \
		           /opt/jdk/jre/lib/amd64/libjavafx*.so \
		           /opt/jdk/jre/lib/amd64/libjfx*.so \
		           /opt/jdk/jre/lib/ext/jfxrt.jar \
		           /opt/jdk/jre/lib/ext/nashorn.jar \
		           /opt/jdk/jre/lib/oblique-fonts \
		           /opt/jdk/jre/lib/plugin.jar \
		           /tmp/* /var/cache/apk/* && \
		    echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf

RUN			wget http://downloads.datastax.com/datastax-ddc/datastax-ddc-${CASSANDRA_VERSION}-bin.tar.gz -P /tmp && \
    		tar -xvzf /tmp/datastax-ddc-${CASSANDRA_VERSION}-bin.tar.gz -C /tmp/ && \
    		rm -rf /tmp/datastax-ddc-${CASSANDRA_VERSION}/javadoc && \
    		mv /tmp/datastax-ddc-${CASSANDRA_VERSION}/* ${CASSANDRA_HOME} && \
    		apk --purge del wget ca-certificates tar && \
    		rm -rf /tmp/datastax-ddc-${CASSANDRA_VERSION}-bin.tar.gz \
     	   		   /tmp/datastax-ddc-${CASSANDRA_VERSION} \
           		   /var/cache/apk/*

USER 		root

RUN			mv ${CASSANDRA_HOME}/conf/* ${CASSANDRA_CONFIG}

COPY 		opt/cassandra.yml ${CASSANDRA_CONFIG}/cassandra.yml
RUN 		a=$(sed -e '/^[[:space:]]*$/d' -e '/^[[:space:]]*#/d' ${CASSANDRA_CONFIG}/cassandra.yml);echo "$a" > ${CASSANDRA_CONFIG}/cassandra.yml

COPY 		opt/commitlog_archiving.properties /${CASSANDRA_CONFIG}/commitlog_archiving.properties

RUN			chmod +x ${CASSANDRA_CONFIG}/*.sh

ENV			PATH=$PATH:${CASSANDRA_HOME}/bin \
    		CASSANDRA_CONF=${CASSANDRA_CONFIG}

WORKDIR		${CASSANDRA_HOME}

VOLUME 		[${CASSANDRA_PERSIST_DIR}]

COPY 		opt/single.sh /usr/local/sbin/single
COPY 		opt/setup.sh /usr/local/sbin/cassandra-setup

RUN			apk add --update --no-cache && \
    		chmod +x /usr/local/sbin/single && \
    		chmod +x /usr/local/sbin/cassandra-setup

RUN 		rm -f /etc/security/limits.d/cassandra.conf

EXPOSE		7000 7001 9042 $READY_PORT

CMD			single

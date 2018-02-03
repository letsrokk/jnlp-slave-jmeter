FROM jenkins/jnlp-slave:3.16-1-alpine
MAINTAINER Dmitry Mayer <mayer.dmitry@gmail.com>

USER root

########################################################
### Update Java security policies
########################################################

RUN wget -O jce_policy.zip  --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip \
  && unzip jce_policy.zip && rm jce_policy.zip \
  && cp UnlimitedJCEPolicyJDK8/*.jar ${JAVA_HOME}/jre/lib/security/

RUN sed -i '/#networkaddress.cache.ttl=-1/c\networkaddress.cache.ttl=0' ${JAVA_HOME}/jre/lib/security/java.security

########################################################
### Install Taurus (bzt)
########################################################

RUN apk update && apk upgrade \
  && apk add libxml2-dev libxslt-dev \
  && apk add py-pip \
  && apk add py-lxml py-libxml2 py-libxslt py-psutil py-virtualenv

RUN pip install bzt && pip install virtualenv

USER jenkins

########################################################
### Install Jmeter
########################################################

ENV JMETER_VERSION 3.3
ENV JMETER_HOME=/home/jenkins/apache-jmeter

RUN wget -O jmeter.zip http://www-eu.apache.org/dist//jmeter/binaries/apache-jmeter-${JMETER_VERSION}.zip \
  && unzip jmeter.zip && rm jmeter.zip \
  && mv apache-jmeter-${JMETER_VERSION} ${JMETER_HOME}

RUN wget -O ${JMETER_HOME}/lib/ext/jmeter-plugins-manager.jar https://jmeter-plugins.org/get/ \
  && wget -O ${JMETER_HOME}/lib/cmdrunner-2.0.jar http://search.maven.org/remotecontent?filepath=kg/apc/cmdrunner/2.0/cmdrunner-2.0.jar \
  && java -cp ${JMETER_HOME}/lib/ext/jmeter-plugins-manager.jar org.jmeterplugins.repository.PluginManagerCMDInstaller

WORKDIR ${JMETER_HOME}
RUN ${JMETER_HOME}/bin/PluginsManagerCMD.sh available \
  && ${JMETER_HOME}/bin/PluginsManagerCMD.sh install jpgc-json \
  && ${JMETER_HOME}/bin/PluginsManagerCMD.sh install jpgc-casutg \
  && ${JMETER_HOME}/bin/PluginsManagerCMD.sh install jpgc-graphs-vs \
  && ${JMETER_HOME}/bin/PluginsManagerCMD.sh install jpgc-perfmon

ENV POSTGRESSQL_DRIVER_VERSION 42.2.1

RUN wget -O ${JMETER_HOME}/lib/postgresql-${POSTGRESSQL_DRIVER_VERSION}.jar https://jdbc.postgresql.org/download/postgresql-${POSTGRESSQL_DRIVER_VERSION}.jar

ENV PATH $PATH:${JMETER_HOME}/bin

WORKDIR ${HOME}

########################################################
### Set Jmeter PerfMon server agent version and url
########################################################

ENV JMETER_SERVER_AGENT_VERSION 2.2.3
ENV JMETER_SERVER_AGENT_DOWNLOAD_URL https://github.com/undera/perfmon-agent/releases/download/${JMETER_SERVER_AGENT_VERSION}/ServerAgent-${JMETER_SERVER_AGENT_VERSION}.zip

ENTRYPOINT ["jenkins-slave", "ash"]
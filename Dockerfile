FROM jenkins/jnlp-slave:3.16-1-alpine
MAINTAINER Dmitry Mayer <mayer.dmitry@gmail.com>

########################################################
### Install Taurus (bzt)
########################################################

USER root

RUN apk update && apk upgrade \
  && apk add libxml2-dev libxslt-dev \
  && apk add py-pip \
  && apk add py-lxml py-libxml2 py-libxslt py-psutil py-virtualenv

RUN pip install bzt

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

ENV PATH $PATH:${JMETER_HOME}/bin

WORKDIR ${HOME}

ENTRYPOINT ["jenkins-slave"]
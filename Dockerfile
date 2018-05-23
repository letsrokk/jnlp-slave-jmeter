FROM jenkins/jnlp-slave:3.19-1
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

RUN apt-get update
RUN apt-get -y install python python-tk python-pip python-dev \
  libxml2-dev libxslt-dev zlib1g-dev net-tools \
  default-jre-headless
RUN pip install bzt

USER jenkins

########################################################
### Install Jmeter
########################################################

ENV JMETER_VERSION 4.0
ENV JMETER_HOME=/home/jenkins/apache-jmeter

RUN wget -O jmeter.zip http://www-eu.apache.org/dist//jmeter/binaries/apache-jmeter-${JMETER_VERSION}.zip \
  && unzip jmeter.zip && rm jmeter.zip \
  && mv apache-jmeter-${JMETER_VERSION} ${JMETER_HOME}

ENV CMDRUNNER_VERSION 2.2

RUN wget -O ${JMETER_HOME}/lib/ext/jmeter-plugins-manager.jar https://jmeter-plugins.org/get/ \
  && wget -O ${JMETER_HOME}/lib/cmdrunner-${CMDRUNNER_VERSION}.jar http://central.maven.org/maven2/kg/apc/cmdrunner/${CMDRUNNER_VERSION}/cmdrunner-${CMDRUNNER_VERSION}.jar \
  && java -cp ${JMETER_HOME}/lib/ext/jmeter-plugins-manager.jar org.jmeterplugins.repository.PluginManagerCMDInstaller

WORKDIR ${JMETER_HOME}

ENV POSTGRESSQL_DRIVER_VERSION 42.2.1
RUN wget -O ${JMETER_HOME}/lib/postgresql-${POSTGRESSQL_DRIVER_VERSION}.jar https://jdbc.postgresql.org/download/postgresql-${POSTGRESSQL_DRIVER_VERSION}.jar

ENV ACTIVEMQ_VERSION 5.15.4
RUN wget -O ${JMETER_HOME}/lib/activemq-all-${POSTGRESSQL_DRIVER_VERSION}.jar http://central.maven.org/maven2/org/apache/activemq/activemq-all/${ACTIVEMQ_VERSION}/activemq-all-${ACTIVEMQ_VERSION}.jar

ENV PATH $PATH:${JMETER_HOME}/bin

WORKDIR ${HOME}

########################################################
### Set Jmeter PerfMon server agent version and url
########################################################

ENV JMETER_SERVER_AGENT_VERSION 2.2.3
ENV JMETER_SERVER_AGENT_DOWNLOAD_URL https://github.com/undera/perfmon-agent/releases/download/${JMETER_SERVER_AGENT_VERSION}/ServerAgent-${JMETER_SERVER_AGENT_VERSION}.zip

ENTRYPOINT ["jenkins-slave"]
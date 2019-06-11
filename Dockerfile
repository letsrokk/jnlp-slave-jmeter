FROM jenkins/jnlp-slave:3.23-1
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

ENV BZT_VERSION 1.13.7
COPY dist/bzt-${BZT_VERSION}.tar.gz /tmp/bzt-${BZT_VERSION}.tar.gz

RUN apt-get update \
    && apt-get -y install python default-jre-headless \
    python-tk python-pip python-dev \
    libxml2-dev libxslt-dev zlib1g-dev net-tools
#RUN pip install virtualenv && pip install bzt==${BZT_VERSION}
#Temporary workaround while Taurus is getting fixed
RUN pip install -f /tmp/bzt-${BZT_VERSION}.tar.gz

USER jenkins

########################################################
### Install Gatling
########################################################

ENV GATLING_VERSION 3.1.2
ENV GATLING_HOME /home/jenkins/gatling

RUN wget -O gatling.zip https://repo1.maven.org/maven2/io/gatling/highcharts/gatling-charts-highcharts-bundle/${GATLING_VERSION}/gatling-charts-highcharts-bundle-${GATLING_VERSION}-bundle.zip \
  && unzip gatling.zip && rm gatling.zip \
  && mv gatling-charts-highcharts-bundle-${GATLING_VERSION} ${GATLING_HOME}

########################################################
### Install Jmeter
########################################################

ENV JMETER_VERSION 5.1.1
ENV JMETER_HOME /home/jenkins/apache-jmeter

RUN wget -O jmeter.zip http://www-eu.apache.org/dist//jmeter/binaries/apache-jmeter-${JMETER_VERSION}.zip \
  && unzip jmeter.zip && rm jmeter.zip \
  && mv apache-jmeter-${JMETER_VERSION} ${JMETER_HOME}

ENV CMDRUNNER_VERSION 2.2.1
#Workaround: PLugin Manager expected Jar with cmrrunner-2.2.jar name
ENV CMDRUNNER_JAR_NAME 2.2

RUN wget -O ${JMETER_HOME}/lib/ext/jmeter-plugins-manager.jar https://jmeter-plugins.org/get/ \
  && wget -O ${JMETER_HOME}/lib/cmdrunner-${CMDRUNNER_JAR_NAME}.jar http://central.maven.org/maven2/kg/apc/cmdrunner/${CMDRUNNER_VERSION}/cmdrunner-${CMDRUNNER_VERSION}.jar \
  && java -cp ${JMETER_HOME}/lib/ext/jmeter-plugins-manager.jar org.jmeterplugins.repository.PluginManagerCMDInstaller

WORKDIR ${JMETER_HOME}
RUN ${JMETER_HOME}/bin/PluginsManagerCMD.sh available \
  && ${JMETER_HOME}/bin/PluginsManagerCMD.sh install-all-except

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

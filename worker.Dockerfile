FROM maven:3-jdk-8

ENV MAVEN_OPTS "-Xmx1024m"

# Copy just the pom files to cache the dependencies
COPY datavault-assembly/pom.xml /tmp/datavault-assembly/pom.xml
COPY datavault-broker/pom.xml /tmp/datavault-broker/pom.xml
COPY datavault-common/pom.xml /tmp/datavault-common/pom.xml
COPY datavault-webapp/pom.xml /tmp/datavault-webapp/pom.xml
COPY datavault-worker/pom.xml /tmp/datavault-worker/pom.xml
COPY pom.xml /tmp
WORKDIR /tmp
RUN mvn -s /usr/share/maven/ref/settings-docker.xml dependency:go-offline --fail-never
# The dependency:go-offline gets a lot of the dependencies, but not all. This would get more, but not sure about other implications
#RUN mvn -s /usr/share/maven/ref/settings-docker.xml install --fail-never

COPY . /usr/src
WORKDIR /usr/src
RUN mvn -s /usr/share/maven/ref/settings-docker.xml clean test package

RUN curl -sLo /usr/local/bin/ep https://github.com/kreuzwerker/envplate/releases/download/v0.0.8/ep-linux && chmod +x /usr/local/bin/ep

FROM openjdk:8-jre-alpine

MAINTAINER William Petit <w.petit@ed.ac.uk>

ENV DATAVAULT_HOME "/docker_datavault-home"

RUN apk add --no-cache bash curl

RUN mkdir -p ${DATAVAULT_HOME}/lib
COPY --from=0 /usr/local/bin/ep /usr/local/bin/ep
COPY --from=0 /usr/src/datavault-worker/target/datavault-worker-1.0-SNAPSHOT-jar-with-dependencies-spring.jar ${DATAVAULT_HOME}/lib/datavault-worker-1.0-SNAPSHOT-jar-with-dependencies-spring.jar
COPY docker/config ${DATAVAULT_HOME}/config
COPY docker/scripts ${DATAVAULT_HOME}/scripts

WORKDIR ${DATAVAULT_HOME}/lib

ENTRYPOINT ["/docker_datavault-home/scripts/docker-entrypoint.sh"]
CMD ["java", "-cp", "datavault-worker-1.0-SNAPSHOT-jar-with-dependencies-spring.jar:./*", "org.datavaultplatform.worker.WorkerInstance"]

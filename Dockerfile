FROM ubuntu:14.04
MAINTAINER Niels Buus
ENV REFRESHED_AT 2015-05-04
ENV DEBAIN_FRONTEND noninteractive

RUN apt-get update -y && \
    apt-get install -y \
      build-essential g++ flex bison gperf ruby perl \
      libsqlite3-dev libfontconfig1-dev libicu-dev libfreetype6 libssl-dev \
      libpng-dev libjpeg-dev python git-core nodejs npm

WORKDIR /var/www/html2pdf
ADD build.tar /var/www/html2pdf
RUN cp bin/phantomjs /usr/local/bin/
RUN npm install
EXPOSE 8080
CMD ["nodejs", "."]

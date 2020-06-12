# A minimal Docker image with Node and Puppeteer
FROM node:10.2.1

# Update
RUN apt-get update && \
      apt-get -y install sudo

## install phantomjs
#
RUN PHANTOMJS_URL="https://circle-downloads.s3.amazonaws.com/circleci-images/cache/linux-amd64/phantomjs-latest.tar.bz2" \
  && sudo apt-get install libfontconfig \
  && curl --silent --show-error --location --fail --retry 3 --output /tmp/phantomjs.tar.bz2 ${PHANTOMJS_URL} \
  && tar -x -C /tmp -f /tmp/phantomjs.tar.bz2 \
  && sudo mv /tmp/phantomjs-*-linux-x86_64/bin/phantomjs /usr/local/bin \
  && rm -rf /tmp/phantomjs.tar.bz2 /tmp/phantomjs-* \
  && phantomjs --version

# install chrome
RUN curl --silent --show-error --location --fail --retry 3 --output /tmp/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
      && (sudo dpkg -i /tmp/google-chrome-stable_current_amd64.deb || sudo apt-get -fy install)  \
      && rm -rf /tmp/google-chrome-stable_current_amd64.deb \
      && sudo sed -i 's|HERE/chrome"|HERE/chrome" --disable-setuid-sandbox --no-sandbox|g' \
           "/opt/google/chrome/google-chrome" \
      && google-chrome --version

RUN export CHROMEDRIVER_RELEASE=$(curl --location --fail --retry 3 http://chromedriver.storage.googleapis.com/LATEST_RELEASE) \
      && curl --silent --show-error --location --fail --retry 3 --output /tmp/chromedriver_linux64.zip "http://chromedriver.storage.googleapis.com/$CHROMEDRIVER_RELEASE/chromedriver_linux64.zip" \
      && cd /tmp \
      && unzip chromedriver_linux64.zip \
      && rm -rf chromedriver_linux64.zip \
      && sudo mv chromedriver /usr/local/bin/chromedriver \
      && sudo chmod +x /usr/local/bin/chromedriver \
      && chromedriver --version
      
# install libgconf-2-4 manually since chrome no longer pulls it in automatically
RUN sudo apt-get install -y libgconf-2-4

# start xvfb automatically to avoid needing to express in gitlab-ci.yml file
ENV DISPLAY :99
RUN printf '#!/bin/sh\nXvfb :99 -screen 0 1280x1024x24 &\nexec "$@"\n' > /tmp/entrypoint \
  && chmod +x /tmp/entrypoint \
        && sudo mv /tmp/entrypoint /docker-entrypoint.sh

# Install Puppeteer under /node_modules so it's available system-wide
ADD package.json package-lock.json /
RUN npm install
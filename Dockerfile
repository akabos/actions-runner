FROM debian:buster-slim

ARG RUNNER_VERSION=2.169.1

RUN apt-get update \
  && apt-get install dumb-init sudo curl git openssh-client ca-certificates gnupg software-properties-common -y --no-install-recommends \
  && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian buster stable" \
  && curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add - \
  && apt-get update \
  && apt-get install -y docker-ce-cli \
  && rm -rf /var/lib/apt/lists/* \
  && adduser --disabled-password --gecos "" --home /opt/runner --uid 1000 runner \
  && usermod -aG sudo runner \
  && echo "%sudo   ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers

RUN mkdir -p /opt/runner \
  && cd /opt/runner \
  && curl -L -o runner.tar.gz https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
  && tar xzf ./runner.tar.gz \
  && rm runner.tar.gz \
  && ./bin/installdependencies.sh \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/runner

COPY known_hosts .ssh/known_hosts

RUN chown -R 1000:1000 .ssh \
 && chmod 0700 .ssh \
 && chmod 0600 .ssh/known_hosts

COPY wrapper.sh ./

USER runner:runner
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/opt/runner/wrapper.sh"]

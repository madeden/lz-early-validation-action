# Container image that runs your code
FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive
ENV CFN_NAG_VERSION=0.3.64

# Update stuff andn install needed packages
RUN apt-get update \
  && apt-get upgrade -y \
  && apt-get install ruby-full -y \
  && gem install cfn-nag -v $CFN_NAG_VERSION \
  && apt-get install zip wget python3-pip libyaml-dev rsync -y \
  && apt-get install python3-numpy python3-scipy python3-pip -y \
  && pip3 install --upgrade setuptools \
  && pip3 install --upgrade virtualenv \
  && pip3 install --upgrade PyYAML \
  && pip3 install --upgrade yorm \
  && pip3 install --upgrade jinja2 \
  && pip3 install --upgrade boto3 \
  && pip3 install --upgrade pyyaml \
  && pip3 install --upgrade pykwalify \
  && pip3 install cfn_flip \
  && pip3 freeze

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY ./validation/custom_validation.py /validation/custom_validation.py
COPY ./validation/manifest.schema.yaml /validation/manifest.schema.yaml
COPY early-validation.sh /entrypoint.sh

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]
CMD []

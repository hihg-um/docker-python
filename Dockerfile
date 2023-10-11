# SPDX-License-Identifier: GPL-2.0
ARG BASE_IMAGE
FROM $BASE_IMAGE

RUN apt -y update -qq && apt -y upgrade && \
    DEBIAN_FRONTEND=noninteractive apt -y install \
	apt-utils \
    python3 \
    python3-venv

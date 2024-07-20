# SPDX-License-Identifier: GPL-2.0
ARG BASE
FROM $BASE

RUN apt -y update -qq && apt -y upgrade && \
	DEBIAN_FRONTEND=noninteractive apt -y install \
	--no-install-recommends --no-install-suggests \
		ca-certificates \
		python3 \
	&& update-alternatives --install /usr/bin/python python \
		/usr/bin/python3 1 \
	&& \
	apt -y clean && rm -rf /var/lib/apt/lists/* /tmp/*

LABEL org.opencontainers.image.description="Python 3 base container"

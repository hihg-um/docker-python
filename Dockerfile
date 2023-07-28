ARG BASE_IMAGE
FROM $BASE_IMAGE

# user data provided by the host system via the make file
# without these, the container will fail-safe and be unable to write output
ARG USERNAME
ARG USERID
ARG USERGNAME
ARG USERGID

ENV SHELL=/bin/bash
SHELL [ "/bin/bash", "-c" ]

# Put the user name and ID into the ENV, so the runtime inherits them
ENV USERNAME=${USERNAME:-nouser} \
	USERID=${USERID:-65533} \
	USERGNAME=${USERGNAME:-users} \
	USERGID=${USERGID:-nogroup}


# Install OS updates, security fixes and utils, generic app dependencies
# We chain this to get it all into one layer. sw-prop-common is needed
# for apt-add-repository, so install that first.
RUN apt -y update -qq && apt -y upgrade && \
	DEBIAN_FRONTEND=noninteractive apt -y install \
    	build-essential \
	ca-certificates curl gcc git openssl \
	software-properties-common vim wget \
	python python-bitarray python-h5py \
	python-numpy \
	python-pandas \
	python-pip \
	python-pysam \
	python-scipy \
	python-sklearn

#RUN pip install plinkio pybedtools
RUN pip install plinkio

# match the building user. This will allow output only where the building
# user has write permissions
RUN groupadd -g $USERGID $USERGNAME && \
	useradd -m -u $USERID -g $USERGID -g "users" $USERNAME && \
	adduser $USERNAME $USERGNAME

WORKDIR /app

RUN git clone https://github.com/bulik/ldsc.git  && \
	bash -c "./ldsc/ldsc.py -h" && bash -c "./ldsc/munge_sumstats.py -h"

RUN git clone https://github.com/yiminghu/AnnoPred.git && \
	echo "LDSC_path /app/ldsc" > AnnoPred/LDSC.config

# we map the user owning the image so permissions for any mapped 
# input/output paths set by the user will work correctly

RUN chown $USERNAME:$USERGID /app
USER $USERNAME
ENV PATH=$PATH:/app/AnnoPred
ENTRYPOINT [ "AnnoPred.py" ]

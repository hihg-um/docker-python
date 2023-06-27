ARG BASE_IMAGE
FROM $BASE_IMAGE

# user data provided by the host system via the make file
# without these, the container will fail-safe and be unable to write output
ARG USERNAME
ARG USERID
ARG USERGNAME
ARG USERGID

# Put the user name and ID into the ENV, so the runtime inherits them
ENV USERNAME=${USERNAME:-nouser} \
	USERID=${USERID:-65533} \
	USERGNAME=${USERGNAME:-users} \
	USERGID=${USERGID:-nogroup}

# match the building user. This will allow output only where the building
# user has write permissions
RUN groupadd -g $USERGID $USERGNAME && \
	useradd -m -u $USERID -g $USERGID -g "users" $USERNAME && \
	adduser $USERNAME $USERGNAME

# Install OS updates, security fixes and utils, generic app dependencies
# We chain this to get it all into one layer. sw-prop-common is needed
# for apt-add-repository, so install that first.

# We assume here, that we want specifically python3.10, rather than
# the standard shipped python version which is in this case 3.9
# Generally depending on a specific version is not best practice,
# since it constrains the portability of the application.
RUN apt -y update -qq && apt -y upgrade && \
	DEBIAN_FRONTEND=noninteractive apt -y install \
	software-properties-common vim \
	python3 python-argparse python3-bitarray \
	python3-nose python3-numpy \
	python3-pandas python3-pip python3-pybedtools \
	python3-scipy python3-h5py && \
	update-alternatives --install /usr/bin/python python \
                 /usr/bin/python3 1

WORKDIR /app

RUN chown -R $USERNAME:$USERGID /app

# we map the user owning the image so permissions for any mapped 
# input/output paths set by the user will work correctly
USER $USERNAME
ENTRYPOINT [ "python" ]

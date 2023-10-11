ARG BASE_IMAGE
FROM $BASE_IMAGE

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

ENTRYPOINT [ "python" ]

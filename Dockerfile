FROM nvidia/cuda:11.1-cudnn8-devel-ubuntu18.04

ENV DEBIAN_FRONTEND=noninteractive
ENV VERSION 7.2.1-1+cuda11.1

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    sudo wget curl git openssh-server \
    # Python3.7用
    python3.7 python3.7-dev python3.7-distutils \
    build-essential libssl-dev libffi-dev\
    # OpenCV-Python 用
    libopencv-dev libgl1-mesa-dev \
    # TensorRT用
    libnvinfer7=${VERSION} libnvonnxparsers7=${VERSION} libnvparsers7=${VERSION} \
    libnvinfer-plugin7=${VERSION} \
    python-libnvinfer=${VERSION} python3-libnvinfer=${VERSION} \
    # その他
    swig \
    && apt-get -y clean \
    && rm -rf /var/lib/apt/lists/*

# TensorRTインストール
ENV TRT_VERSION 7.2.1.6
COPY TensorRT-${TRT_VERSION}.Ubuntu-18.04.x86_64-gnu.cuda-11.1.cudnn8.0.tar.gz ./
RUN tar xzvf TensorRT-${TRT_VERSION}*.tar.gz
RUN cp -r TensorRT-${TRT_VERSION} /usr/local/
RUN export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/TensorRT-${TRT_VERSION}/lib
RUN rm -rf TensorRT-${TRT_VERSION}*

# Pythonパッケージのインストール
RUN curl -kL https://bootstrap.pypa.io/get-pip.py | sudo python3.7
RUN python3.7 -m pip install torch==1.7.1+cu110 torchvision==0.8.2+cu110 torchaudio===0.7.2 -f https://download.pytorch.org/whl/torch_stable.html
RUN python3.7 -m pip install pytorch-lightning==1.1.0 mlflow==1.12.1 gorilla==0.3.0
RUN python3.7 -m pip install opencv-python==4.4.0.46 opencv-contrib-python
RUN python3.7 -m pip install -U git+https://github.com/albumentations-team/albumentations
RUN python3.7 -m pip install scikit-image==0.17.2 scikit-learn==0.23.2
RUN python3.7 -m pip install onnx==1.8.0
RUN python3.7 -m pip install timm==0.3.2 torch_optimizer==0.0.1a17 addict==2.4.0
RUN python3.7 -m pip install /usr/local/TensorRT-${TRT_VERSION}/python/tensorrt-${TRT_VERSION}-cp37-none-linux_x86_64.whl \
    /usr/local/TensorRT-${TRT_VERSION}/onnx_graphsurgeon/onnx_graphsurgeon-0.2.6-py2.py3-none-any.whl
# RUN python3.7 -m pip install hydra-core==1.0.4 --upgrade
RUN python3.7 -m pip install flake8==3.8.4 autopep8==1.5.4

# PyCUDAインストール
RUN curl -OL https://files.pythonhosted.org/packages/46/61/47d3235a4c13eec5a5f03594ddb268f4858734e02980afbcd806e6242fa5/pycuda-2020.1.tar.gz
RUN tar xfz pycuda-2020.1.tar.gz 
WORKDIR /pycuda-2020.1 
RUN python3.7 configure.py --cuda-root=/usr/local/cuda 
RUN make install 
WORKDIR /
RUN rm -rf pycuda-*

# sudo権限を持つ一般ユーザーを作成
ENV USER dev
ENV GROUP dev
ENV UID 1000
ENV GID 1000
ENV HOME /home/${USER}
ENV SHELL /bin/bash

RUN groupadd -g ${GID} ${GROUP}
RUN useradd -u ${UID} -g ${GROUP} -m ${USER}
RUN gpasswd -a ${USER} sudo
RUN echo "${USER}:dev" | chpasswd
RUN sed -i.bak "s#${HOME}:#${HOME}:${SHELL}#" /etc/passwd

USER ${USER}
WORKDIR ${HOME}
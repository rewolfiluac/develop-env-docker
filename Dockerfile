FROM nvidia/cuda:11.1-cudnn8-runtime-ubuntu18.04

ENV DEBIAN_FRONTEND=noninteractive
ENV VERSION 7.2.1-1+cuda11.1

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    sudo wget curl git openssh-server \
    # Python3.7用
    python3.7 python3.7-dev python3.7-distutils \
    # OpenCV-Python 用
    libopencv-dev libgl1-mesa-dev \
    # TensorRT用
    libnvinfer7=${VERSION} libnvonnxparsers7=${VERSION} libnvparsers7=${VERSION} \
    libnvinfer-plugin7=${VERSION} \
    python-libnvinfer=${VERSION} python3-libnvinfer=${VERSION} \
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

# sudo権限を持つ一般ユーザーを作成
ENV USER dev
ENV HOME /home/${USER}
ENV SHELL /bin/bash

RUN useradd -m ${USER}
RUN gpasswd -a ${USER} sudo
RUN echo "${USER}:dev" | chpasswd
RUN sed -i.bak "s#${HOME}:#${HOME}:${SHELL}#" /etc/passwd

USER ${USER}
WORKDIR ${HOME}




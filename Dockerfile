FROM nvidia/cuda:11.1-cudnn8-devel-ubuntu18.04

ARG UID
ARG GID

ENV DEBIAN_FRONTEND=noninteractive
ENV VERSION 7.2.1-1+cuda11.1
ENV TRT_VERSION 7.2.1.6
ENV USER dev
ENV GROUP dev
ENV UID ${UID}
ENV GID ${GID}
ENV HOME /home/${USER}
ENV SHELL /bin/bash

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    sudo tzdata wget curl git vim \
    # Build Tool
    cmake extra-cmake-modules build-essential libssl-dev libffi-dev pkg-config \
    ccache ecm mesa-utils \
    # Media I/O, OpenCVビルド用
    zlib1g-dev \
    libjpeg-dev \
    libwebp-dev \
    libpng-dev \
    libtiff5-dev \
    libopenexr-dev \
    libgdal-dev \
    libgtk2.0-dev \
    # Video I/O, OpenCVビルド用
    libdc1394-22-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libtheora-dev \
    libvorbis-dev \
    libxvidcore-dev \
    libx264-dev \
    yasm \
    libopencore-amrnb-dev \
    libopencore-amrwb-dev \
    libv4l-dev \
    libxine2-dev \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libopencv-highgui-dev \
    ffmpeg \
    # 並列処理と線形代数, OpenCVビルド用
    libtbb-dev \
    libeigen3-dev \
    # Python3.7用
    python3.7 python3.7-dev python3.7-tk python3.7-distutils \
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

# Pythonパッケージのインストール
RUN curl -kL https://bootstrap.pypa.io/get-pip.py | sudo python3.7 && \
    python3.7 -m pip install numpy \
    torch==1.7.1+cu110 torchvision==0.8.2+cu110 torchaudio===0.7.2 -f https://download.pytorch.org/whl/torch_stable.html \
    pytorch-lightning==1.1.0 mlflow==1.12.1 gorilla==0.3.0 \
    scikit-image==0.17.2 scikit-learn==0.23.2 \
    onnx==1.8.0 \
    timm==0.3.2 torch_optimizer==0.0.1a17 addict==2.4.0 \
    flake8==3.8.4 autopep8==1.5.4 \
    -U git+https://github.com/albumentations-team/albumentations
# albumentaions でインストールされるので手動削除。
RUN python3.7 -m pip uninstall -y opencv_python opencv_python_headless

# PyCUDAインストール
WORKDIR /
RUN curl -OL https://files.pythonhosted.org/packages/46/61/47d3235a4c13eec5a5f03594ddb268f4858734e02980afbcd806e6242fa5/pycuda-2020.1.tar.gz && \
    tar xfz pycuda-2020.1.tar.gz 
WORKDIR /pycuda-2020.1 
RUN python3.7 configure.py --cuda-root=/usr/local/cuda && \
    make install 
WORKDIR /
RUN rm -rf pycuda-*

# TensorRTインストール
WORKDIR /opt
COPY TensorRT-${TRT_VERSION}*.tar.gz ./
RUN tar xzvf TensorRT-${TRT_VERSION}*.tar.gz && \
    cp -r TensorRT-${TRT_VERSION} /usr/local/ && \
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/TensorRT-${TRT_VERSION}/lib && \
    rm -rf TensorRT-${TRT_VERSION}* && \
    python3.7 -m pip install /usr/local/TensorRT-${TRT_VERSION}/python/tensorrt-${TRT_VERSION}-cp37-none-linux_x86_64.whl \
    /usr/local/TensorRT-${TRT_VERSION}/onnx_graphsurgeon/onnx_graphsurgeon-0.2.6-py2.py3-none-any.whl

# Build OpenCV
RUN git clone --depth=1 https://github.com/opencv/opencv.git && \
    git clone --depth=1 https://github.com/opencv/opencv_contrib.git && \
    cd opencv && mkdir build && cd build && \
    CC=gcc-7 CXX=g++-7 cmake \
    -D OPENCV_GENERATE_PKGCONFIG=ON \
    -D WITH_TBB=ON \
    -D CMAKE_BUILD_TYPE=RELEASE \
    -D BUILD_EXAMPLES=ON \
    -D WITH_FFMPEG=ON \
    -D WITH_V4L=ON \
    -D WITH_OPENGL=ON \
    -D WITH_CUDA=ON \
    -D CUDA_ARCH_BIN=8.6 \
    -D CUDA_ARCH_PTX=8.6 \
    -D WITH_CUBLAS=ON \
    -D WITH_CUFFT=ON \
    -D WITH_EIGEN=ON \
    -D PYTHON3_EXECUTABLE=/usr/bin/python3.7m \
    -D PYTHON3_LIBRARY=/usr/lib/x86_64-linux-gnu/libpython3.7m.so \
    -D PYTHON_INCLUDE_DIR=/usr/include/python3.7m \
    -D PYTHON_PACKAGES_PATH=/usr/local/lib/python3.7/dist-packages/ \
    -D PYTHON_NUMPY_INCLUDE_DIR=/usr/local/lib/python3.7/dist-packages/numpy/core/include/ \
    -D EIGEN_INCLUDE_PATH=/usr/include/eigen3 \
    -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules/ \
    .. && \
    make all -j$(nproc) && \
    make install && \
    ldconfig -v

# sudo権限を持つ一般ユーザーを作成
RUN groupadd -g ${GID} ${GROUP} && \
    useradd -u ${UID} -g ${GROUP} -m ${USER} && \
    gpasswd -a ${USER} sudo && \
    echo "${USER}:dev" | chpasswd && \
    sed -i.bak "s#${HOME}:#${HOME}:${SHELL}#" /etc/passwd

USER ${USER}
WORKDIR ${HOME}

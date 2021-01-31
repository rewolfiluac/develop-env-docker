# develop-env-docker
## Contained Environment
- Python3.7
- PyCUDA (Python3.7)
- TensorRT (C++/Python3.7)
- OpenCV with CUDA Build (C++/Python3.7)
- その他Pythonモジュール (Python3.7)

## TensorRTのダウンロード
以下のURLから、「TensorRT 7.2.1 for Ubuntu 18.04 and CUDA 11.1 TAR package」をダウンロード <br>
> https://developer.nvidia.com/nvidia-tensorrt-7x-download <br>

ダウンロードしたTARファイルを、リポジトリ直下へコピー <br>
## Docker Image のビルド
```
UID=${UID} GID=${GID} docker-compose build
docker-compose up
```

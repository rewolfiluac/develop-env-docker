# develop-env-docker
## TensorRTのダウンロード
以下のURLから、「TensorRT 7.2.1 for Ubuntu 18.04 and CUDA 11.1 TAR package」をダウンロード <br>
> https://developer.nvidia.com/nvidia-tensorrt-7x-download <br>

ダウンロードしたTARファイルを、リポジトリ直下へコピー <br>
## Docker Image のビルド
```
docker build -t {image-name} .
```
## Dockerコンテナの実行
```
docker run -itd --gpus all -p {port}:22 {image-name}
```
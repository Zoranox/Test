# syntax=docker/dockerfile:labs
#FROM debian:bullseye-slim
FROM nvidia/cuda:11.8.0-base-ubuntu20.04
ENV DEBIAN_FRONTEND=noninteractive 
RUN apt update
RUN apt install -y wget git python3 python3-venv bash wget curl jq vim
#RUN useradd -m user
#RUN apt install -y libgl1-mesa-glx libglib2.0-0
#USER user
#RUN bash <<EOF
#  export COMMANDLINE_ARGS="--skip-torch-cuda-test"
#  $(wget -qO- https://raw.githubusercontent.com/AUTOMATIC1111/stable-diffusion-webui/master/webui.sh)
#EOF
#ADD https://github.com/cmdr2/stable-diffusion-ui.git /app
ADD . /app/
WORKDIR /app
RUN <<EOT
mkdir -p dist/linux-mac/stable-diffusion-ui/scripts
cp scripts/on_env_start.sh dist/linux-mac/stable-diffusion-ui/scripts/
cp scripts/bootstrap.sh dist/linux-mac/stable-diffusion-ui/scripts/
cp scripts/functions.sh dist/linux-mac/stable-diffusion-ui/scripts/
cp scripts/start.sh dist/linux-mac/stable-diffusion-ui/
cp LICENSE dist/linux-mac/stable-diffusion-ui/
cp "CreativeML Open RAIL-M License" dist/linux-mac/stable-diffusion-ui/
cp "How to install and run.txt" dist/linux-mac/stable-diffusion-ui/
echo "" > dist/linux-mac/stable-diffusion-ui/scripts/install_status.txt
EOT

WORKDIR /app
RUN sed -i 's/^cd.*//' scripts/start.sh 
RUN sed -i 's/^scripts/\.\/scripts/g' scripts/start.sh 
RUN apt install -y libgl1 python3-opencv
RUN apt install -y axel
#ADD --link https://huggingface.co/stabilityai/stable-diffusion-2-base/resolve/main/512-base-ema.ckpt /app/model/
VOLUME /app/models
VOLUME /app/installer_files
ENV PATH "/app:$PATH"
CMD "/app/scripts/start.sh"


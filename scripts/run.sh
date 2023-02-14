#!/bin/bash
cd "$(dirname "${BASH_SOURCE[0]}")"
mkdir -p ../models/{stable-diffusion,gfpgan,realesrgan,vae}


declare -a models=(
    "sd-v1-4.ckpt 4265380512 stable-diffusion https://huggingface.co/CompVis/stable-diffusion-v-1-4-original/resolve/main/sd-v1-4.ckpt"
    "512-base-ema.ckpt 5214864007 stable-diffusion https://huggingface.co/stabilityai/stable-diffusion-2-base/resolve/main/512-base-ema.ckpt"
    "v2-1_768-ema-pruned.ckpt 5214865159 stable-diffusion https://huggingface.co/stabilityai/stable-diffusion-2-1/resolve/main/v2-1_768-ema-pruned.ckpt"
    "GFPGANv1.3.pth 348632874 gfpgan https://github.com/TencentARC/GFPGAN/releases/download/v1.3.0/GFPGANv1.3.pth"
    "RealESRGAN_x4plus.pth 67040989 realesrgan https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth"
    "RealESRGAN_x4plus_anime_6B.pth 17938799 realesrgan https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.2.4/RealESRGAN_x4plus_anime_6B.pth"
    "vae-ft-mse-840000-ema-pruned.ckpt 334695179 vae https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/main/vae-ft-mse-840000-ema-pruned.ckpt"
    "openjourney-v2.ckpt 2132887840 stable-diffusion https://huggingface.co/prompthero/openjourney-v2/resolve/main/openjourney-v2.ckpt"
)

model_dir="../models"

for model in "${models[@]}"; do
    IFS=" " read -r model_file expected_size model_subdir model_url <<< "$model"
    model_path="$model_dir/$model_subdir/${model_file}"
    if [ -f "$model_path" ]; then
        model_size=$(find "$model_path" -printf "%s")
        if [ "$model_size" -eq "$expected_size" ]; then
            echo "Data files (weights) necessary for ${model_file} were already downloaded"
        else
            printf "\n\nThe model file present at ${model_path} is invalid. It is only $model_size bytes in size. Re-downloading..\n"
            rm "$model_path"
        fi
    fi

    if [ ! -f "$model_path" ]; then
        echo "Downloading data files (weights) for ${model_file}.."

        wget -O "$model_path" "$model_url"

        if [ -f "$model_path" ]; then
            model_size=$(find "$model_path" -printf "%s")
            if [ ! "$model_size" -eq "$expected_size" ]; then
                fail "The downloaded ${model_file} model file was invalid! Bytes downloaded: $model_size"
            fi
        else
            fail "Error downloading the data files (weights) for ${model_file}"
        fi
    fi
done

#if [ `grep -c ../sd_install_complete ./install_status.txt` -gt "0" ]; then
    echo sd_weights_downloaded >> ../scripts/install_status.txt
    echo sd_install_complete >> ../scripts/install_status.txt
#fi

printf "\n\nStable Diffusion is ready!\n\n"

SD_PATH=`pwd`

export PYTHONPATH=/app/installer_files/env/lib/python3.8/site-packages
echo "PYTHONPATH=$PYTHONPATH"

which python
python --version

cd ..
export SD_UI_PATH=`pwd`/ui
echo "SD_UI_PATH=$SD_UI_PATH"
cd stable-diffusion

uvicorn main:server_api --app-dir "$SD_UI_PATH" --port ${SD_UI_BIND_PORT:-9000} --host ${SD_UI_BIND_IP:-0.0.0.0} --log-level error

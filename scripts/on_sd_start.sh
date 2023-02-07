#!/bin/bash

source ./scripts/functions.sh


# activate the installer env
CONDA_BASEPATH=$(conda info --base)
source "$CONDA_BASEPATH/etc/profile.d/conda.sh" # avoids the 'shell not initialized' error

conda activate || fail "Failed to activate conda"

# remove the old version of the dev console script, if it's still present
if [ -e "open_dev_console.sh" ]; then
    rm "open_dev_console.sh"
fi

# python -c "import os; import shutil; frm = 'sd-ui-files/ui/hotfix/9c24e6cd9f499d02c4f21a033736dabd365962dc80fe3aeb57a8f85ea45a20a3.26fead7ea4f0f843f6eb4055dfd25693f1a71f3c6871b184042d4b126244e142'; dst = os.path.join(os.path.expanduser('~'), '.cache', 'huggingface', 'transformers', '9c24e6cd9f499d02c4f21a033736dabd365962dc80fe3aeb57a8f85ea45a20a3.26fead7ea4f0f843f6eb4055dfd25693f1a71f3c6871b184042d4b126244e142'); shutil.copyfile(frm, dst) if os.path.exists(dst) else print(''); print('Hotfixed broken JSON file from OpenAI');" 

# Caution, this file will make your eyes and brain bleed. It's such an unholy mess.
# Note to self: Please rewrite this in Python. For the sake of your own sanity.

# set the correct installer path (current vs legacy)
if [ -e "installer_files/env" ]; then
    export INSTALL_ENV_DIR="$(pwd)/installer_files/env"
fi
if [ -e "stable-diffusion/env" ]; then
    export INSTALL_ENV_DIR="$(pwd)/stable-diffusion/env"
fi

# create the stable-diffusion folder, to work with legacy installations
if [ ! -e "stable-diffusion" ]; then mkdir stable-diffusion; fi
cd stable-diffusion

# activate the old stable-diffusion env, if it exists
if [ -e "env" ]; then
    conda activate ./env || fail "conda activate failed"
fi

# disable the legacy src and ldm folder (otherwise this prevents installing gfpgan and realesrgan)
if [ -e "src" ]; then mv src src-old; fi
if [ -e "ldm" ]; then mv ldm ldm-old; fi

mkdir -p "../models/stable-diffusion"
mkdir -p "../models/gfpgan"
mkdir -p "../models/realesrgan"
mkdir -p "../models/vae"

# migrate the legacy models to the correct path (if already downloaded)
if [ -e "sd-v1-4.ckpt" ]; then mv sd-v1-4.ckpt ../models/stable-diffusion/; fi
if [ -e "custom-model.ckpt" ]; then mv custom-model.ckpt ../models/stable-diffusion/; fi
if [ -e "GFPGANv1.3.pth" ]; then mv GFPGANv1.3.pth ../models/gfpgan/; fi
if [ -e "RealESRGAN_x4plus.pth" ]; then mv RealESRGAN_x4plus.pth ../models/realesrgan/; fi
if [ -e "RealESRGAN_x4plus_anime_6B.pth" ]; then mv RealESRGAN_x4plus_anime_6B.pth ../models/realesrgan/; fi

# install torch and torchvision
if python ../scripts/check_modules.py torch torchvision; then
    echo "torch and torchvision have already been installed."
else
    echo "Installing torch and torchvision.."

    export PYTHONNOUSERSITE=1
    export PYTHONPATH="$INSTALL_ENV_DIR/lib/python3.8/site-packages"

    if python -m pip install --upgrade torch torchvision --extra-index-url https://download.pytorch.org/whl/cu116 ; then
        echo "Installed."
    else
        fail "torch install failed" 
    fi
fi

# install/upgrade sdkit
if python ../scripts/check_modules.py sdkit sdkit.models ldm transformers numpy antlr4 gfpgan realesrgan ; then
    echo "sdkit is already installed."

    # skip sdkit upgrade if in developer-mode
    if [ ! -e "../src/sdkit" ]; then
        export PYTHONNOUSERSITE=1
        export PYTHONPATH="$INSTALL_ENV_DIR/lib/python3.8/site-packages"

        python -m pip install --upgrade sdkit -q
    fi
else
    echo "Installing sdkit: https://pypi.org/project/sdkit/"

    export PYTHONNOUSERSITE=1
    export PYTHONPATH="$INSTALL_ENV_DIR/lib/python3.8/site-packages"

    if python -m pip install sdkit ; then
        echo "Installed."
    else
        fail "sdkit install failed"
    fi
fi

python -c "from importlib.metadata import version; print('sdkit version:', version('sdkit'))"

# upgrade stable-diffusion-sdkit
python -m pip install --upgrade stable-diffusion-sdkit -q
python -c "from importlib.metadata import version; print('stable-diffusion version:', version('stable-diffusion-sdkit'))"

# install rich
if python ../scripts/check_modules.py rich; then
    echo "rich has already been installed."
else
    echo "Installing rich.."

    export PYTHONNOUSERSITE=1
    export PYTHONPATH="$INSTALL_ENV_DIR/lib/python3.8/site-packages"

    if python -m pip install rich ; then
        echo "Installed."
    else
        fail "Install failed for rich"
    fi
fi

if python ../scripts/check_modules.py uvicorn fastapi ; then
    echo "Packages necessary for Stable Diffusion UI were already installed"
else
    printf "\n\nDownloading packages necessary for Stable Diffusion UI..\n\n"

    export PYTHONNOUSERSITE=1
    export PYTHONPATH="$INSTALL_ENV_DIR/lib/python3.8/site-packages"

    if conda install -c conda-forge -y uvicorn fastapi ; then
        echo "Installed. Testing.."
    else
        fail "'conda install uvicorn' failed" 
    fi

    if ! command -v uvicorn &> /dev/null; then
        fail "UI packages not found!"
    fi
fi



#if [ `grep -c ../sd_install_complete ./install_status.txt` -gt "0" ]; then
    echo sd_weights_downloaded >> ../scripts/install_status.txt
    echo sd_install_complete >> ../scripts/install_status.txt
#fi

printf "\n\nStable Diffusion is ready!\n\n"

SD_PATH=`pwd`

export PYTHONPATH="$INSTALL_ENV_DIR/lib/python3.8/site-packages"
echo "PYTHONPATH=$PYTHONPATH"

which python
python --version

cd ..
export SD_UI_PATH=`pwd`/ui
cd stable-diffusion

exit 0

#uvicorn main:server_api --app-dir "$SD_UI_PATH" --port ${SD_UI_BIND_PORT:-9000} --host ${SD_UI_BIND_IP:-0.0.0.0} --log-level error

#read -p "Press any key to continue"

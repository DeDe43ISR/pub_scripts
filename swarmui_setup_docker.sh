#!/bin/bash

# Pretty message function for easier readability
print_message() {
    echo "========================================"
    echo "$1"
    echo "========================================"
}

# Help function to display usage information
show_help() {
    echo "Usage: ./your_script.sh [options]"
    echo ""
    echo "Options:"
    echo "  -b                Download core models (basic models)"
    echo "  -g                Download GGUF models"
    echo "  -y                Download YIGAL models"
    echo "  -m                Download LLM model (Mistral-7B-Instruct-v0.3.Q4_K_M.gguf)"
    echo "  -c                Download custom models"
    echo "  -l                Launch StableSwarmUI"
    echo "  --help            Show this help message and exit"
    echo ""
    echo "Examples:"
    echo "  ./your_script.sh -b              # Download core models"
    echo "  ./your_script.sh -y -l           # Download YIGAL models and launch StableSwarmUI"
    echo "  ./your_script.sh -m -g           # Download LLM and GGUF models"
    echo "  ./your_script.sh -c              # Download custom models"
    echo "  ./your_script.sh --help          # Display this help message"
}

# Set the directory where you want to save the files
MODELS_DIR="/models"
LORA_DIR="$MODELS_DIR/Lora"
SWARM_UI_DIR="/SwarmUI/"
CLOUDFLARED_DEB="$HOME/cloudflared-linux-amd64.deb"
LLM_DIR="$SWARM_UI_DIR/dlbackend/ComfyUI/models/llm_gguf"
SWARM_UI_MODELS_DIR="$SWARM_UI_DIR/Models"

# Export Hugging Face transfer optimization environment variable
export HF_HUB_ENABLE_HF_TRANSFER=1

# Ensure the LLM directory exists
mkdir -p "$LLM_DIR"

# Print start message
print_message "Starting the setup: Downloading models and configuring StableSwarmUI"

# Function to check and install pip packages if needed
check_and_install_pip_packages() {
    local packages=("huggingface_hub[hf_transfer,cli]" "hf_transfer")  # Packages to install

    # Install packages in the main environment
    for package in "${packages[@]}"; do
        if ! pip show "$package" > /dev/null 2>&1; then
            print_message "Installing $package in main environment..."
            pip install -U "$package"
        else
            print_message "$package is already installed in main environment, skipping."
        fi
    done

    # Activate virtual environment and install hf_transfer
    print_message "Activating virtual environment and installing hf_transfer"
    source "$SWARM_UI_DIR/dlbackend/ComfyUI/venv/bin/activate"

    if ! pip show "hf_transfer" > /dev/null 2>&1; then
        print_message "Installing hf_transfer in virtual environment..."
        pip install -U "hf_transfer"
    else
        print_message "hf_transfer is already installed in virtual environment, skipping."
    fi

    deactivate  # Deactivate the virtual environment
}

# Function to download and create symbolic links for models
download_and_link() {
    local repo=$1         # Add repository as first parameter
    local model=$2        # File name (model)
    local target_dir=$3   # Directory where the model should be saved
    local link_dir=$4     # Directory where the symbolic link should be created

    # Check if the file already exists
    if [[ -f "$target_dir/$model" ]]; then
        print_message "Model $model already exists, skipping download."
    else
        print_message "Downloading $model from $repo"
        huggingface-cli download "$repo" "$model" --local-dir "$target_dir"
    fi

    mkdir -p "$link_dir"
    # Create symbolic link if not already linked
    if [[ ! -L "$link_dir/$model" ]]; then
        print_message "Creating symbolic link for $model"
        ln -sf "$target_dir/$model" "$link_dir/$model"
    fi
}

# Function to download core models (now -b flag)
download_core_models() {
    print_message "Downloading core models"
    download_and_link "OwlMaster/realgg" "flux1-dev.safetensors" "$MODELS_DIR" "$SWARM_UI_MODELS_DIR/unet"
    download_and_link "comfyanonymous/flux_text_encoders" "clip_l.safetensors" "$MODELS_DIR" "$SWARM_UI_MODELS_DIR/clip"
    download_and_link "comfyanonymous/flux_text_encoders" "t5xxl_fp16.safetensors" "$MODELS_DIR" "$SWARM_UI_MODELS_DIR/clip"
    download_and_link "OwlMaster/realgg" "ae.safetensors" "$MODELS_DIR" "$SWARM_UI_MODELS_DIR/VAE"
}

# Function to download GGUF models (now -g flag)
download_gguf_models() {
    print_message "Downloading GGUF models"
    download_and_link "city96/FLUX.1-dev-gguf" "flux1-dev-Q8_0.gguf" "$MODELS_DIR" "$SWARM_UI_MODELS_DIR/unet"
    download_and_link "city96/t5-v1_1-xxl-encoder-gguf" "t5-v1_1-xxl-encoder-Q8_0.gguf" "$MODELS_DIR" "$SWARM_UI_MODELS_DIR/clip"
    download_and_link "city96/t5-v1_1-xxl-encoder-gguf" "t5-v1_1-xxl-encoder-f16.gguf" "$MODELS_DIR" "$SWARM_UI_MODELS_DIR/clip"
}

# Function to download YIGAL models (now -y flag)
download_yigal_models() {
    print_message "Downloading YIGAL models"
    download_and_link "dededinuo/yigal_new" "yigal_new.safetensors" "$LORA_DIR" "$SWARM_UI_MODELS_DIR/Lora"
    download_and_link "dededinuo/yigal" "Rank_1_SLOW_YIGAL-000175.safetensors" "$LORA_DIR" "$SWARM_UI_MODELS_DIR/Lora"
    download_and_link "dededinuo/yigal_v2" "Rank_1_SLOW_4x_GPU.safetensors" "$LORA_DIR" "$SWARM_UI_MODELS_DIR/Lora"
}

# Function to download the LLM model (new -m flag) into the specified LLM_DIR
download_llm_model() {
    print_message "Downloading LLM model"
    download_and_link "MaziyarPanahi/Mistral-7B-Instruct-v0.3-GGUF" "Mistral-7B-Instruct-v0.3.Q8_0.gguf" "$LLM_DIR" "$LLM_DIR"
}

# Function to download custom models (new -c flag) into the Lora directory
download_custom_models() {
    declare -A models=(
        [storyboard]=869189
        [anime]=820300
        [anime_art]=931713
        [adventure-comic-book]=841709
        [retro_anime]=806265
        [dieselpunk]=888290
        [neonfantasy]=798521
        [cyberpunk_anime_style]=747534
        [niji]=754068
        [anime_art_style]=879824
        [MJanime_Flux_LoRa_v3_Final]=837239
        [Velvets_Mythic]=753053
    )

    print_message "Downloading custom models"

    # Download all models in the background
    for model_name in "${!models[@]}"; do
        model_id=${models[$model_name]}
        wget "https://civitai.com/api/download/models/${model_id}?token=$CIVITAI_TOKEN" -O "$LORA_DIR/${model_name}.safetensors" &
    done

    # Wait for all downloads to finish
    wait

    # Creating symbolic links
    print_message "Creating symbolic links"
    for model_name in "${!models[@]}"; do
        ln -sf "$LORA_DIR/${model_name}.safetensors" "$SWARM_UI_MODELS_DIR/Lora/${model_name}.safetensors"
    done
}

# Check and install cloudflared if not already downloaded
check_cloudflared() {
    print_message "Checking for cloudflared"

    # Check if cloudflared is installed via dpkg
    if dpkg -l | grep -q "cloudflared"; then
        print_message "cloudflared is already installed"
        return
    fi

    # Check if the cloudflared DEB file exists, download if not
    if [[ -f "$CLOUDFLARED_DEB" ]]; then
        print_message "cloudflared DEB package already exists"
    else
        print_message "Downloading cloudflared"
        wget https://github.com/cloudflare/cloudflared/releases/download/2024.11.0/cloudflared-linux-amd64.deb -O "$CLOUDFLARED_DEB"
    fi

    # Install cloudflared using apt
    print_message "Installing cloudflared using apt"
    sudo apt install "$CLOUDFLARED_DEB"
}


# Check and install pip packages if needed
check_and_install_pip_packages


# Parse command line arguments
DOWNLOAD_CORE=false
DOWNLOAD_GGUF=false
DOWNLOAD_YIGAL=false
DOWNLOAD_LLM=false
DOWNLOAD_CUSTOM=false
LAUNCH=false

if [ $# -eq 0 ] || [[ "$1" == "--help" ]]; then
    show_help
    exit 0
fi

for arg in "$@"
do
    case $arg in
        -b)
        DOWNLOAD_CORE=true
        ;;
        -g)
        DOWNLOAD_GGUF=true
        ;;
        -y)
        DOWNLOAD_YIGAL=true
        ;;
        -m)
        DOWNLOAD_LLM=true
        ;;
        -c)
        DOWNLOAD_CUSTOM=true
        ;;
        -l)
        LAUNCH=true
        ;;
        --help)
        show_help
        exit 0
        ;;
    esac
done

# Execute downloads based on flags
if [ "$DOWNLOAD_CORE" = true ]; then
    download_core_models
fi

if [ "$DOWNLOAD_GGUF" = true ]; then
    download_gguf_models
fi

if [ "$DOWNLOAD_YIGAL" = true ]; then
    download_yigal_models
fi

if [ "$DOWNLOAD_LLM" = true ]; then
    download_llm_model
fi

if [ "$DOWNLOAD_CUSTOM" = true ]; then
    download_custom_models
fi

# Check and install cloudflared if needed
check_cloudflared

# Launch StableSwarmUI only if -l flag is provided
if [ "$LAUNCH" = true ]; then
    print_message "Launching StableSwarmUI"
    cd "$SWARM_UI_DIR"
    git pull
    ##git reset --hard 3122b8ab7fdef6d6c2a4199d771b23cdbcbbfc2a
    ./launch-linux.sh --launch_mode none --cloudflared-path cloudflared
else
    print_message "Skipping StableSwarmUI launch as per default or no -l flag"
fi

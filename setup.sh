#!/bin/bash

set -e  # Остановит выполнение при ошибке

# Проверяем, установлен ли expect
if ! command -v expect &> /dev/null; then
    echo "🔧 Expect не найден. Устанавливаем..."
    sudo apt-get install -y expect
else
    echo "✅ Expect уже установлен."
fi

# Устанавливаем переменную окружения для отключения интерактивных запросов
export DEBIAN_FRONTEND=noninteractive

# Подавляем вопросы debconf
echo "debconf debconf/frontend select Noninteractive" | sudo debconf-set-selections

echo "🔄 Обновление системы..."
sudo apt update && sudo apt upgrade -y

echo "🦀 Установка Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --no-modify-path -y
source $HOME/.cargo/env  # Подключаем Rust без перезагрузки

echo "🛠️ Установка целевой архитектуры Rust..."
rustup target add riscv32i-unknown-none-elf

echo "📦 Установка необходимых пакетов..."
sudo apt-get install -y git-all gcc pkg-config libssl-dev unzip tmux

echo "📥 Установка Protocol Buffers (protoc)..."
PROTOC_ZIP="protoc-21.12-linux-x86_64.zip"
wget -q https://github.com/protocolbuffers/protobuf/releases/download/v21.12/$PROTOC_ZIP
unzip -o $PROTOC_ZIP -d $HOME/.local
rm $PROTOC_ZIP  # Удаляем архив после распаковки

# Добавляем protoc в PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
export PATH="$HOME/.local/bin:$PATH"

echo "✅ Установка завершена! Перезапустите терминал или выполните 'source ~/.bashrc' для обновления окружения."

# ✅ Запуск tmux-сессии "nexus"
echo "🚀 Запуск tmux-сессии 'nexus'..."
tmux new-session -d -s nexus  # Запускаем tmux в фоне

# Ждём немного, чтобы tmux полностью запустился
sleep 2

# Отправляем команду на создание swap-файла
tmux send-keys -t nexus "sudo dd if=/dev/zero of=/swapfile bs=1M count=8192 && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile && echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab" C-m

# Ждём завершения swap-команды
sleep 25

# Отправляем команду установки Nexus CLI и автоматический ответ "y"
tmux send-keys -t nexus "curl https://cli.nexus.xyz/ | sh" C-m
sleep 7
tmux send-keys -t nexus "y" C-m

# ✅ Оставляем открытую сессию tmux
tmux attach -t nexus

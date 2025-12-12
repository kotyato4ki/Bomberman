#!/bin/bash
# Скрипт для запуска клиентов
# Использование: ./run_clients.sh

cd "$(dirname "$0")"
source venv/bin/activate
python client/main.py


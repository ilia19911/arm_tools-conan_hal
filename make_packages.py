import time

import git
import subprocess
import shutil
import os

# "STM32F0", "STM32F1", "STM32F3", "STM32F4", "STM32H7"
repositories = {
    ("https://github.com/STMicroelectronics/stm32f0xx-hal-driver.git", "STM32F0", "armv6"),
    ("https://github.com/STMicroelectronics/stm32f1xx_hal_driver.git", "STM32F1", "armv7"),
    ("https://github.com/STMicroelectronics/stm32f3xx_hal_driver", "STM32F3", "armv7"),
    ("https://github.com/STMicroelectronics/stm32f4xx_hal_driver.git", "STM32F4", "armv7"),
    ("https://github.com/STMicroelectronics/stm32h7xx_hal_driver.git", "STM32H7", "armv7"),
}


for url, device, arch in repositories:
    if os.path.exists("./hal"):
        shutil.rmtree("./hal")
    # time.sleep(5)
    repo = git.Repo.clone_from(url, "./hal")
    tags = repo.tags
    print("tag: ", tags)
    for tag in tags:
        comand = f"export URL=\"{url}\" && export TAG=\"{tag}\" && conan create . --name=hal_{device.lower()} --version={str(tag).lower()} -pr:h=./profiles/{arch}"
        print(comand)
        result = subprocess.run(comand, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

        if result.returncode == 0:
            comand = f" conan upload hal_{device.lower()}/{tag} -r=nexus.iahve.space"
            result = subprocess.run(comand, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            print("Команда завершилась успешно")
            print("Вывод команды:", result.stdout)
        if result.returncode !=0:
            print("Команда завершилась с ошибкой")
            print("Ошибка:", result.stderr)
            raise ValueError(f"сборка пакета не удалась, почините скрипт сборки")
        # time.sleep(5)

#export URL="https://oauth2:bb8czxqpbkzn5PHp3nda@git.orlan.in/breo_mcu/drivers/CMSIS_5.git" && export TAG="5.9.1-dev" && conan create . --version=5.9.1-dev --build-require

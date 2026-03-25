# Recovery slot (4 GB microSD)

Сюда **не коммитятся** сами образы — только описание и скрипт. Бинарники большие; храни их на диске или в артефактах CI.

## Что положить

- Минимальный **known-good** образ для платы из текущей сборки (лаб: **Orange Pi One**, `orange-pi-one`): загрузка, SSH, сеть, утилиты восстановления.
- Имя по соглашению:

  `cryptowallet-recovery-<yyyy-mm-dd>-<git-sha>.img.zst`

- Контрольная сумма рядом: `.sha256`

## Откуда взять образ

1. Собрать в Yocto (`bitbake cryptowallet-image` или `core-image-minimal`) и взять `.wic` / `.img` из каталога деплоя для `MACHINE`, например **`/data/projects/poky/build/tmp/deploy/images/orange-pi-one/`** (или `build/tmp/deploy/images/orange-pi-one/` внутри дерева Poky).
2. Или экспортировать с рабочей 4 GB карты:

   ```bash
   sudo dd if=/dev/mmcblk0 bs=4M status=progress | zstd -19 -T0 -o cryptowallet-recovery-$(date +%F).img.zst
   sha256sum cryptowallet-recovery-*.img.zst > cryptowallet-recovery-*.img.zst.sha256
   ```

## Скопировать артефакт в этот каталог

Из корня репозитория (после сборки):

```bash
cd /data/projects/CryptoWallet-NanoPI
# подставь реальное имя .wic/.img из deploy (зависит от IMAGE_FSTYPES)
./infra/nanopi/images/recovery/stage-from-deploy.sh /data/projects/poky/build/tmp/deploy/images/orange-pi-one/core-image-minimal-orange-pi-one.wic
# или уже сжатый образ рядом:
./infra/nanopi/images/recovery/stage-from-deploy.sh /data/projects/CryptoWallet-NanoPI/cryptowallet-recovery-2025-03-01.img.zst
```

Скрипт кладёт копию с датой в **этот** каталог (не в git).

## Использование

- Подписать SD как **RESCUE-4** наклейкой.
- В аварии: вставить карту, загрузиться, починить основную систему или перепрошить dev-карту.

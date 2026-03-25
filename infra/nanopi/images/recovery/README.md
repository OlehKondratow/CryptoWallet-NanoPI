# Recovery slot (4 GB microSD)

Сюда **не коммитятся** сами образы — только описание и скрипт. Бинарники большие; храни их на диске или в артефактах CI.

## Что положить

- Минимальный **known-good** образ для NanoPi NEO: загрузка, SSH, сеть, утилиты восстановления.
- Имя по соглашению:

  `cryptowallet-recovery-<yyyy-mm-dd>-<git-sha>.img.zst`

- Контрольная сумма рядом: `.sha256`

## Откуда взять образ

1. Собрать в Yocto (`bitbake cryptowallet-image` или `core-image-minimal`) и взять `.wic` / `.img` из `build/tmp/deploy/images/nanopi-neo/`.
2. Или экспортировать с рабочей 4 GB карты:

   ```bash
   sudo dd if=/dev/mmcblk0 bs=4M status=progress | zstd -19 -T0 -o cryptowallet-recovery-$(date +%F).img.zst
   sha256sum cryptowallet-recovery-*.img.zst > cryptowallet-recovery-*.img.zst.sha256
   ```

## Скопировать артефакт в этот каталог

Из корня репозитория (после сборки):

```bash
./infra/nanopi/images/recovery/stage-from-deploy.sh /path/to/image.wic
# или
./infra/nanopi/images/recovery/stage-from-deploy.sh /path/to/file.img.zst
```

Скрипт кладёт копию с датой в **этот** каталог (не в git).

## Использование

- Подписать SD как **RESCUE-4** наклейкой.
- В аварии: вставить карту, загрузиться, починить основную систему или перепрошить dev-карту.

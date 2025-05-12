# Sbertech-SecureDevelopment

## Контрольное суммирование файлов dlib

Клонируем репозиторий dlib:

```
$ git clone https://github.com/davisking/dlib.git
```

На этом же уровне создаем исполняемый файл checksums.sh с таким содержимым:

```
#!/bin/bash

CHECKSUM_FILE="dlib_checksums.sha256"

find ./dlib -type f -print0 | while IFS= read -r -d $'\0' file; do
    sha256sum "$file" >> "$CHECKSUM_FILE"
done

echo "Контрольные суммы SHA256 сохранены в: $CHECKSUM_FILE"
```
Этот скрипт пробегает по всем файлам проекта dlib от корня и при помощи команды sha256sum вычисляет контрольную сумму файла. Весь вывод перенаправляется в файл dlib_checksums.sha256

## Фаззинг-тестирование библиотеки dlib

Dlib - это библиотека C++, содержащая алгоритмы машинного обучения и инструменты создания программного обеспечения на языке C++. Поэтому для проведения фаззинг-тестирования будет использоваться инструмент AFL++ и сам эксперимент будет проводиться на Ubuntu 22.10.

### Сборка AFL++

Скачиваем репозиторий фаззера AFL++ на тот же уровень, где лежит проект dlib, и собираем при помощи команд ниже:

```
$ git clone https://github.com/AFLplusplus/AFLplusplus
$ cd AFLplusplus
$ make distrib
$ sudo make install
```

### Подготовка проекта dlib к фаззингу

> Примечание: перед сборкой необходимо установить все необходимые пакеты, сборка будет завершаться с ошибками и указывать на недостающие библиотеки. Необходимо установить все недостающие пакеты при помощи apt-get install и заново пересобрать dlib.

Настраиваем санитайзеры:

```
$ cd dlib/tools/imglab
$ mkdir -p build
$ cd build

$ export AFL_USE_UBSAN=1
$ export AFL_USE_ASAN=1
$ export ASAN_OPTIONS="detect_leaks=1:abort_on_error=1:allow_user_segv_handler=0:handle_abort=1:symbolize=0"

$ cmake -DCMAKE_C_COMPILER=afl-clang-fast -DCMAKE_CXX_COMPILER=afl-clang-fast++ -DCMAKE_CXX_FLAGS="-fsanitize=address,leak,undefined -g" -DCMAKE_C_FLAGS="-fsanitize=address,leak,undefined -g" ..
$ make -j8
```

### Проведение эксперимента

Создаем отдельную папку fuzz на уровне с dlib и AFLplusplus, в которую передадим входные seed и в которую выведем результаты тестирования

```
$ mkdir -p fuzz/image/in
$ cp /home/$USER/dlib/examples/faces/testing.xml fuzz/image/in
```

Запуск:

```
$ afl-fuzz -i fuzz/image/in -o fuzz/image/out -- dlib/tools/imglab/build/imglab --stats @@
```

Запускаем тест на несколько часов, чтоб получить более информативный отчет и получаем что-то похожее:

<img width="554" alt="Снимок экрана 2025-04-15 в 09 11 19" src="https://github.com/user-attachments/assets/09445cf4-a20b-48d0-b877-75669d282e12" />

## Сбор покрытия

Необходимо пересобрать проект dlib с новыми добавленными флагами:

```
$ cmake -DCMAKE_C_COMPILER=afl-clang-fast -DCMAKE_CXX_COMPILER=afl-clang-fast++
      -DCMAKE_CXX_FLAGS="-fsanitize=address,leak,undefined -g -fprofile-arcs -ftest-coverage"
      -DCMAKE_C_FLAGS="-fsanitize=address,leak,undefined -g -fprofile-arcs -ftest-coverage"
      -DCMAKE_BUILD_TYPE=Coverage
```

Далее пересобираем аналогично при помощи make и запускаем AFL++, как до этого. После прогона собираем все тестовые данные, на которых хотим посмотреть покрытие:

```
$ mkdir coverage_data
$ cp fuzz/image/out/default/queue/* coverage_data/
```

На этих тестовых данных запускаем бинарный файл и генерируем .gcda файлы:

```
$ cd coverage_data

$ for file in *; do
      ../dlib/tools/imglab/build/imglab --stats "$file"
  done
```

<img width="291" alt="Снимок экрана 2025-05-12 в 03 05 32" src="https://github.com/user-attachments/assets/f2e15f5a-b618-4c86-9b5f-e12cbe2a20d7" />

<img width="237" alt="Снимок экрана 2025-05-12 в 03 06 06" src="https://github.com/user-attachments/assets/db3fbfd6-85b6-473d-b566-7fbf48056374" />

Для просмотра процента покрытия вводим команду:

```
$ llvm-cov <ИМЯ_ФАЙЛА>.gcda
```

![image](https://github.com/user-attachments/assets/94049418-e91d-4f26-96d5-3f07e596b862)


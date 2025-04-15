# Sbertech-SecureDevelopment

## Фаззинг-тестирование библиотеки dlib

Dlib - это библиотека C++, содержащая алгоритмы машинного обучения и инструменты создания программного обеспечения на языке C++. Поэтому для проведения фаззинг-тестирования будет использоваться инструмент AFL++ и сам эксперимент будет проводиться на Ubuntu 22.10.

### Сборка AFL++

Скачиваем репозиторий фаззера AFL++ и собираем при помощи команд ниже:

```
$ git clone https://github.com/AFLplusplus/AFLplusplus
$ cd AFLplusplus
$ make distrib
$ sudo make install
```

### Подготовка проекта dlib к фаззингу

> Примечание: перед сборкой необходимо установить все необходимые пакеты, сборка будет завершаться с ошибками и указывать на недостающие библиотеки. Необходимо установить все недостающие пакеты при помощи apt-get install и заново пересобрать dlib.

Клонируем репозиторий dlib на тот же уровень, где лежит AFLplusplus:

```
$ git clone https://github.com/davisking/dlib.git
```

Далее настраиваем санитайзеры:

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


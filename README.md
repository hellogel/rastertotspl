# CUPS TSPL2 Filter

CUPS-фільтр для перетворення растрових даних у TSPL2-команди для принтерів етикеток, сумісних з EZPOS L4-W та іншими китайськими клон-принтерами на базі TSPL.

## Особливості

- ✅ Підтримка стандартного CUPS Raster формату
- ✅ Генерація TSPL2-команд для принтерів етикеток
- ✅ Налаштування щільності друку (1-15)
- ✅ Налаштування швидкості друку (1-6)
- ✅ Підтримка користувацьких розмірів етикеток
- ✅ Автоматичне визначення розмірів з DPI
- ✅ Підтримка монохромних та відтінків сірого
- ✅ Оптимізовано для Raspberry Pi 4B

## Вимоги

- Linux ARM (Raspberry Pi OS Bookworm або новіше)
- CUPS >= 2.3
- GCC з підтримкою C99
- CUPS development headers

### Встановлення залежностей

```bash
sudo apt-get update
sudo apt-get install build-essential libcups2-dev cups-filters
```

## Збірка

```bash
# Перевірити наявність CUPS
make check-cups

# Зібрати фільтр
make

# Або з налагодженням
make debug
```

## Встановлення

```bash
# Встановити фільтр у систему
sudo make install
```

Це скопіює `rastertotspl` у `/usr/lib/cups/filter/` з правильними правами доступу.

## Налаштування принтера

### 1. Створити PPD файл

Створіть або відредагуйте PPD файл для вашого принтера, додавши рядок:

```ppd
*cupsFilter: "application/vnd.cups-raster 0 rastertotspl"
```

### 2. Додати принтер через CUPS

```bash
# Веб-інтерфейс CUPS
open http://localhost:631

# Або через командний рядок
sudo lpadmin -p tspl-printer -v usb://... -P your-printer.ppd -E
```

## Використання

### Основне використання

```bash
# Друк PDF
lpr -P tspl-printer document.pdf

# Друк зображення
lpr -P tspl-printer image.png

# Друк тексту
echo "Test Label" | lpr -P tspl-printer
```

### Параметри друку

```bash
# Налаштування щільності (1-15, за замовчуванням: 8)
lpr -P tspl-printer -o density=12 document.pdf

# Налаштування швидкості (1-6, за замовчуванням: 4)
lpr -P tspl-printer -o speed=2 document.pdf

# Користувацькі розміри етикетки
lpr -P tspl-printer -o label-width=50mm -o label-height=30mm document.pdf

# Поворот на 90 градусів
lpr -P tspl-printer -o rotate=90 document.pdf

# Комбінація параметрів
lpr -P tspl-printer -o density=10 -o speed=3 -o label-width=60mm document.pdf
```

## Налагодження

### Перевірка роботи фільтра

```bash
# Створити тестовий растр
gs -sDEVICE=cups -r203x203 -g400x600 -o test.raster test.pdf

# Протестувати фільтр
./rastertotspl 1 user title 1 "" test.raster > output.tspl

# Переглянути згенеровані команди
cat output.tspl
```

### Лог-файли CUPS

```bash
# Увімкнути налагодження в CUPS
sudo cupsctl --debug-logging

# Переглянути логи
sudo tail -f /var/log/cups/error_log
```

### Моніторинг USB-трафіку

```bash
# Встановити usbmon
sudo modprobe usbmon

# Перехопити трафік (замініть usb1 на відповідний пристрій)
sudo cat /sys/kernel/debug/usb/usbmon/1u
```

## Приклад згенерованих TSPL-команд

Для етикетки 50×30 мм при 203 DPI:

```tspl
SIZE 50.0 mm,30.0 mm
GAP 2 mm,0
DENSITY 8
SPEED 4
DIRECTION 1
CLS
BITMAP 0,0,128,240,0,FFFFFFFF00000000...
PRINT 1
```

## Підтримувані формати

- **Вхідні**: PDF, PNG, JPEG, GIF, PostScript через CUPS
- **Проміжні**: CUPS Raster (application/vnd.cups-raster)
- **Вихідні**: TSPL2 команди

## Відомі обмеження

- Підтримка лише чорно-білого друку
- Максимальна ширина: обмежена принтером (зазвичай 104мм для 4" принтерів)
- Компресія RLE поки не реалізована

## Видалення

```bash
sudo make uninstall
```

## Ліцензія

MIT License - дивіться файл LICENSE для деталей.

## Підтримка

При виникненні проблем:

1. Перевірте логи CUPS: `/var/log/cups/error_log`
2. Протестуйте фільтр окремо з тестовими даними
3. Перевірте USB-з'єднання з принтером
4. Переконайтесь, що PPD файл містить правильний cupsFilter

## Розробка

### Додавання нових функцій

Фільтр підтримує розширення для:
- Команд BARCODE/QRCODE
- Різних DPI (200/300)
- RLE-компресії для BITMAP
- Підтримки кольорових режимів

### Тестування

```bash
# Запустити тести збірки
make test-build

# Очистити і перезібрати
make clean all
```

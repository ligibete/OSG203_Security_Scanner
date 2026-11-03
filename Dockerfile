# 1. Dùng hệ điều hành Linux siêu nhẹ có sẵn Python
FROM python:3.11-slim

# 2. Tạo thư mục làm việc bên trong container
WORKDIR /app

# 3. Copy file thư viện vào và cài đặt Flask
COPY requirements.txt .
RUN pip install -r requirements.txt

# 4. Cài đặt Docker CLI (Cực kỳ quan trọng để app.py gọi được lệnh quét)
RUN apt-get update && apt-get install -y docker.io sqlite3

# 5. Copy toàn bộ code web (app.py, templates/...) của em vào container
COPY . .

# 6. Mở cổng 5001 cho giao diện web
EXPOSE 5001

# 7. Lệnh tự động chạy web khi bật container
CMD ["python3", "app.py"]



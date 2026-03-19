# Usar una imagen base ligera y segura
FROM python:3.11-slim

# Establecer el directorio de trabajo
WORKDIR /app

# Copiar requirements primero para aprovechar la caché de Docker
COPY requirements.txt .

# Instalar dependencias
RUN apt-get update && apt-get install -y gcc curl && \
    pip install --no-cache-dir -r requirements.txt && \
    addgroup --gid 1000 no-root && \
    useradd --uid 1000 --gid 1000 --no-create-home --shell /bin/false no-root && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copiar el código de la aplicación
COPY techwave-app.py .

# Asegurar permisos para el usuario no-root
RUN chown -R no-root:no-root /app

# Exponer el puerto
EXPOSE 5000

# Cambiar al usuario no-root antes de ejecutar
USER no-root

# Comando para ejecutar la aplicación
CMD ["python", "techwave-app.py"]

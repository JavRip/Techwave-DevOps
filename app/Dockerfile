# Etapa 1: Builder
FROM python:3.11-slim AS builder

# Establecer el directorio de trabajo
WORKDIR /app

# Establecer directorio de caché
ENV CACHE_DIR=/app/cache

# Copiar requirements primero para aprovechar la caché de Docker
COPY requirements.txt .

# Instalar dependencias
RUN apt-get update && apt-get install -y gcc && \
    pip install --no-cache-dir -r requirements.txt && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Etapa 2: Runtime
FROM python:3.11-slim

# Establecer el directorio de trabajo
WORKDIR /app

# Establecer directorio de caché
ENV CACHE_DIR=/app/cache

# Copiar dependencias ya compiladas desde la etapa builder
COPY --from=builder /usr/local/lib/python3.11/site-packages/ /usr/local/lib/python3.11/site-packages/
COPY --from=builder /usr/local/bin/ /usr/local/bin/

# Crear usuario no-root y curl
RUN apt-get update && apt-get install -y curl && \
    addgroup --gid 1000 no-root && \
    useradd --uid 1000 --gid 1000 --no-create-home --shell /bin/false no-root && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
	
# Copiar el código de la aplicación
COPY techwave_app.py .

# Asegurar permisos para el usuario no-root
RUN chown -R no-root:no-root /app

# Exponer el puerto
EXPOSE 5000

# Cambiar al usuario no-root antes de ejecutar
USER no-root

# Comando para ejecutar la aplicación
CMD ["python", "techwave_app.py"]

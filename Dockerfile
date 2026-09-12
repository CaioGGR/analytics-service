###### ==============================================================================
###### ESTÁGIO DE COMPILAÇÃO (BUILD STAGE)
###### ==============================================================================
###### Utiliza a imagem oficial do Python 3.9 (versão slim, reduzida, baseada em Debian)
FROM python:3.9-slim AS builder

WORKDIR /app

###### Cria o ambiente virtual de Python (/opt/venv) para isolar as dependências
RUN python -m venv /opt/venv

###### Ativa o venv no PATH para garantir que o pip e o python utilizados sejam os do ambiente virtual
ENV PATH="/opt/venv/bin:$PATH"

###### Otimização de Cache: Copia apenas o requirements.txt primeiro
COPY requirements.txt .

###### Instala as bibliotecas de forma otimizada (sem cache do pip)
RUN pip install --no-cache-dir -r requirements.txt

###### ==============================================================================
###### ESTÁGIO DE EXECUÇÃO (FINAL STAGE)
###### ==============================================================================
###### Usa a mesma imagem base enxuta para consistência, agora para rodar a aplicação
FROM python:3.9-slim

###### Define fuso horário, certificados (essencial para AWS) e atualiza pacotes com correções de segurança
RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends ca-certificates tzdata \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

###### Criação de grupo e usuário de sistema sem privilégios (non-root)
RUN addgroup --system appgroup && adduser --system --group appuser

###### Copia o ambiente virtual pronto do estágio de build
COPY --from=builder /opt/venv /opt/venv

###### Copia o código-fonte da aplicação
COPY . .

###### Ativa o ambiente virtual globalmente no container final
ENV PATH="/opt/venv/bin:$PATH"

###### Ajusta a propriedade do código e do venv para o usuário não-root
RUN chown -R appuser:appgroup /app /opt/venv

###### Define a execução do container utilizando o usuário não-root criado
USER appuser

###### Define a porta padrão do analytics-service
ENV PORT=8005
EXPOSE 8005

###### Executa o Gunicorn lendo a porta mapeada
CMD ["gunicorn", "--bind", "0.0.0.0:8005", "app:app"]

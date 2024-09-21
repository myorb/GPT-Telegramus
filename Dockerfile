# Use official Python image
FROM python:3.10-slim AS build

# Install necessary system dependencies and pyinstaller
RUN apt-get update && \
    apt-get install -y git binutils build-essential && \
    pip install pyinstaller

# Install Python dependencies from requirements.txt
COPY requirements.txt .
RUN pip install -r requirements.txt

# Set working directory and build the executable using pyinstaller
WORKDIR /src
COPY . .
RUN pyinstaller --specpath /app --distpath /app/dist --workpath /app/work \
    --hidden-import tiktoken_ext.openai_public \
    --onefile --name telegramus main.py

# Start a new stage for the final image
FROM alpine:latest

# Set environment variables
ENV TELEGRAMUS_CONFIG_FILE "/app/config.json"
ENV PATH /app:$PATH

# Copy necessary libraries from the build stage
COPY --from=build /lib /lib
COPY --from=build /lib64 /lib64

# Copy the built application from the build stage
COPY --from=build /app/dist/telegramus /app/telegramus

# Set the working directory and copy other necessary files
WORKDIR /app
COPY config.json /app/
COPY module_configs/ /app/module_configs/
COPY langs/ /app/langs/

# Set the default command to run the application
CMD ["./telegramus"]

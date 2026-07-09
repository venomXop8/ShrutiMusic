FROM nikolaik/python-nodejs:python3.10-nodejs20

# Install FFmpeg with retries, timeouts, and fallback
RUN set -ex; \
    echo "Installing FFmpeg..."; \
    \
    # Try primary source with retry logic
    curl -L --retry 5 --retry-delay 10 --connect-timeout 30 --max-time 300 \
        https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz \
        -o ffmpeg.tar.xz || \
    \
    # Fallback to GitHub BtbN builds if primary fails
    (echo "Primary source failed, trying fallback..." && \
     curl -L --retry 5 --retry-delay 10 --connect-timeout 30 --max-time 300 \
        https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linux64-gpl.tar.xz \
        -o ffmpeg.tar.xz); \
    \
    # Extract and install
    tar -xJf ffmpeg.tar.xz; \
    mv ffmpeg-*-static/ffmpeg /usr/local/bin/ || \
    mv ffmpeg-*_linux64/ffmpeg /usr/local/bin/; \
    mv ffmpeg-*-static/ffprobe /usr/local/bin/ || \
    mv ffmpeg-*_linux64/ffprobe /usr/local/bin/; \
    rm -rf ffmpeg*; \
    \
    # Verify installation
    ffmpeg -version

COPY . /app/
WORKDIR /app/

# Use --default-timeout and cache for reliability
RUN pip3 install --no-cache-dir --default-timeout=100 -r requirements.txt

# Make start script executable
RUN chmod +x start 2>/dev/null || true

CMD ["bash", "start"]

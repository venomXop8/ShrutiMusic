FROM nikolaik/python-nodejs:python3.10-nodejs20

# Install FFmpeg with multiple fallback methods
RUN set -ex; \
    echo "=== Installing FFmpeg ==="; \
    \
    # METHOD 1: APT (most reliable)
    echo "Method 1: Trying APT..."; \
    apt-get update && \
    apt-get install -y ffmpeg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    ffmpeg -version && \
    echo "✅ APT installation successful" || \
    \
    # METHOD 2: JohnVansickle static build
    (echo "Method 2: Trying JohnVansickle static build..."; \
     curl -L --retry 5 --retry-delay 10 --connect-timeout 30 --max-time 300 \
        https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz \
        -o ffmpeg.tar.xz && \
     tar -xJf ffmpeg.tar.xz && \
     mv ffmpeg-*-static/ffmpeg /usr/local/bin/ && \
     mv ffmpeg-*-static/ffprobe /usr/local/bin/ && \
     rm -rf ffmpeg* && \
     ffmpeg -version && \
     echo "✅ JohnVansickle installation successful") || \
    \
    # METHOD 3: BtbN GitHub builds
    (echo "Method 3: Trying BtbN GitHub builds..."; \
     curl -L --retry 5 --retry-delay 10 --connect-timeout 30 --max-time 300 \
        https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linux64-gpl.tar.xz \
        -o ffmpeg.tar.xz && \
     tar -xJf ffmpeg.tar.xz && \
     find . -name "ffmpeg" -type f -exec mv {} /usr/local/bin/ \; && \
     find . -name "ffprobe" -type f -exec mv {} /usr/local/bin/ \; && \
     rm -rf ffmpeg* && \
     ffmpeg -version && \
     echo "✅ BtbN installation successful") || \
    \
    # METHOD 4: Build from source (last resort)
    (echo "Method 4: Building FFmpeg from source..."; \
     apt-get update && \
     apt-get install -y --no-install-recommends \
        build-essential \
        yasm \
        libx264-dev \
        libx265-dev \
        libvpx-dev \
        libfdk-aac-dev \
        libmp3lame-dev \
        libopus-dev \
        wget && \
     wget -O ffmpeg-src.tar.gz https://ffmpeg.org/releases/ffmpeg-6.1.1.tar.gz && \
     tar -xzf ffmpeg-src.tar.gz && \
     cd ffmpeg-* && \
     ./configure \
        --prefix=/usr/local \
        --enable-gpl \
        --enable-nonfree \
        --enable-libx264 \
        --enable-libx265 \
        --enable-libvpx \
        --enable-libfdk-aac \
        --enable-libmp3lame \
        --enable-libopus \
        --extra-libs="-lpthread -lm" && \
     make -j$(nproc) && \
     make install && \
     cd .. && \
     rm -rf ffmpeg* && \
     apt-get remove -y build-essential yasm wget && \
     apt-get autoremove -y && \
     apt-get clean && \
     rm -rf /var/lib/apt/lists/* && \
     ffmpeg -version && \
     echo "✅ Source build successful") || \
    \
    # If all methods fail
    (echo "❌ All FFmpeg installation methods failed!"; exit 1)

COPY . /app/
WORKDIR /app/

RUN pip3 install --no-cache-dir -r requirements.txt

CMD ["bash", "start"]

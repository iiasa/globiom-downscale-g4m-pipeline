FROM ubuntu:22.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    g++ python3 ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt/globiom-g4m-results-merge
COPY convert_country.cpp merge_g4m.py ./
COPY vendor/ ./vendor/
RUN g++ -std=c++17 -Dunix -O2 convert_country.cpp -o convert-country


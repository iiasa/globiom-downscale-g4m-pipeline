FROM registry.iiasa.ac.at/accelerator/globiom-region59-g4m-collector:6424b86

USER root
RUN apt-get update && apt-get install -y --no-install-recommends python3 && \
    rm -rf /var/lib/apt/lists/*

COPY --chown=65534:65534 sets_g4m.gms 8c_rep_iamc_g4m_newIAMCSept24.gms /opt/globiom/Model/
COPY --chown=65534:65534 report.py /opt/globiom-combined-report/report.py

WORKDIR /opt/globiom/Model
CMD ["python3", "/opt/globiom-combined-report/report.py"]

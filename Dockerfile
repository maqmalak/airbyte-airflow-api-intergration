FROM apache/airflow:2.5.1

ARG AIRFLOW_USER_HOME=/opt/airflow

ENV PYTHONPATH=$PYTHONPATH:${AIRFLOW_USER_HOME}

USER airflow

RUN pip3 install --upgrade pip && \
    pip3 install bs4 && \
    pip3 install apache-airflow-providers-http && \
    pip3 install apache-airflow-providers-airbyte

RUN mkdir ${AIRFLOW_USER_HOME}/outputs

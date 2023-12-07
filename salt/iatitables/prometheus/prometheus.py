import time
import os
import subprocess

from prometheus_client import write_to_textfile, Gauge, CollectorRegistry

OUTPUT_FILENAME = os.getenv("OUTPUT_FILENAME", "output.txt")
# Latest in LATEST_LOG_FILE_IN_DIRECTORIES is defined as "last modified file".
# If we add log rotation later we might have to be careful with that definition.
LATEST_LOG_FILE_IN_DIRECTORIES = [i.strip() for i in os.getenv("LATEST_LOG_FILE_IN_DIRECTORIES", "").split(",") if i.strip()]

registry = CollectorRegistry()
iatitables_metrics_collected_at_timestamp_gauge = Gauge('iatitables_metrics_collected_at_timestamp', 'IATI Tables, timestamp when metrics where collected', registry=registry)
iatitables_latest_log_file_in_directory_size_gauge = Gauge('iatitables_latest_log_file_in_directory_size', 'IATI Tables, Latest log file in directory file size', ['directory'], registry=registry)
iatitables_latest_log_file_in_directory_modified_time_gauge = Gauge('iatitables_latest_log_file_in_directory_modified_time', 'IATI Tables, Latest log file in directory file modified_time', ['directory'], registry=registry)

def collect_metrics():
    #################### Latest log file in diretories
    for logs_dir in LATEST_LOG_FILE_IN_DIRECTORIES:
        output = subprocess.check_output("ls -tp | grep -v /$ | head -1", cwd=logs_dir, shell=True, text=True).strip()
        if output:
            iatitables_latest_log_file_in_directory_size_gauge.labels(directory=logs_dir).set(os.path.getsize(os.path.join(logs_dir, output)))
            iatitables_latest_log_file_in_directory_modified_time_gauge.labels(directory=logs_dir).set(os.path.getmtime(os.path.join(logs_dir, output)))

    #################### Collected at
    iatitables_metrics_collected_at_timestamp_gauge.set(time.time())


if __name__ == '__main__':
    collect_metrics()
    write_to_textfile(OUTPUT_FILENAME,registry)

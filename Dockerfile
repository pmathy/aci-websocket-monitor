# Start from official Python docker image
FROM python:3.8

# Create required directories and set workdir.
RUN mkdir -p /home/requirements /home/scripts /home/templates /home/config /home/data /home/internal
WORKDIR /home/scripts

# Install all required packages. Requirements file contains the necessary python
# packages.
COPY ./inputData/requirements/ /home/requirements/
RUN pip install -r /home/requirements/requirements.txt

# Copy files with scripts and config data, set permissions.
COPY ./inputData/scripts/ /home/scripts/
RUN chmod +x /home/scripts/start.py
COPY ./inputData/templates/ /home/templates/
COPY ./inputData/config/ /home/config/

# Define the default command to run when starting the container.
# This command keeps the container running as because the websocket is being
# kept open.
ENTRYPOINT [ "nohup", "python", "/home/scripts/start.py", "&" ]